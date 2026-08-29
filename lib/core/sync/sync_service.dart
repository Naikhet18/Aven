import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:khao_piyo_pos/core/database/database.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = AppDatabase(); // Usually provided via another provider, simplified here
  return SyncService(db, Supabase.instance.client);
});

class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService(this._db, this._supabase);

  void start() {
    if (_syncTimer != null) return;
    _initConnectivityListener();
    _startPeriodicSync();
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        // Internet came back online, attempt an immediate sync flush
        triggerSync();
      }
    });
  }

  void _startPeriodicSync() {
    // Periodically check queue as a fallback
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => triggerSync());
  }

  /// Pushes an operation to the local queue. 
  /// The UI calls this instead of calling Supabase directly.
  Future<void> queueMutation({
    required String operation,
    required String targetTable,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncOperations).insert(
      SyncOperationsCompanion.insert(
        operation: operation,
        targetTable: targetTable,
        recordId: recordId,
        payload: jsonEncode(payload),
        status: const drift.Value('PENDING'),
      ),
    );
    
    // Attempt immediate sync
    triggerSync();
  }

  /// Flushes the local SyncOperations queue to Supabase
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Check if we actually have internet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.any((r) => r != ConnectivityResult.none)) {
        _isSyncing = false;
        return; 
      }

      // 2. Fetch pending operations from local DB
      final pendingOps = await (_db.select(_db.syncOperations)
            ..where((t) => t.status.equals('PENDING'))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
          .get();

      if (pendingOps.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 3. Process operations sequentially
      for (final op in pendingOps) {
        bool success = false;
        try {
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;
          
          if (op.operation == 'INSERT') {
            await _supabase.from(op.targetTable).insert(payload);
          } else if (op.operation == 'UPDATE') {
            await _supabase.from(op.targetTable).update(payload).eq('id', op.recordId);
          } else if (op.operation == 'DELETE') {
            await _supabase.from(op.targetTable).delete().eq('id', op.recordId);
          }

          success = true;
        } catch (e) {
          // In a production app, we would handle specific Supabase errors (e.g. constraints)
          print('Sync Error for op ${op.id}: $e');
        }

        // 4. Update local queue status
        if (success) {
          await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(op.id))).go();
        } else {
          // Increment retry count
          await (_db.update(_db.syncOperations)..where((t) => t.id.equals(op.id))).write(
            SyncOperationsCompanion(
              retryCount: drift.Value(op.retryCount + 1),
              status: drift.Value(op.retryCount >= 5 ? 'FAILED' : 'PENDING'),
            ),
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
