import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/utils/app_logger.dart';

typedef RemoteRowHandler = Future<void> Function(Map<String, dynamic> row);

/// Describes one remote table this device keeps in sync locally: how to pull
/// changed rows (which timestamp column to page through) and how to merge a
/// remote row into the local Drift database.
class SyncableTable {
  final String table;
  final String timestampColumn; // 'updated_at' for mutable rows, 'created_at' for append-only ledgers
  final RemoteRowHandler upsertFromRemote;

  const SyncableTable({
    required this.table,
    required this.upsertFromRemote,
    this.timestampColumn = 'updated_at',
  });
}

/// Offline-first, bidirectional sync engine.
///
/// - PUSH: local writes are queued (via [queueMutation]) into the
///   `sync_operations` table and flushed to Supabase in the background,
///   with retry/back-off.
/// - PULL: on a timer and whenever connectivity returns, each registered
///   [SyncableTable] is paged for rows changed since the last successful
///   pull and merged into the local database.
/// - REALTIME: a Supabase Realtime channel is also opened for the same
///   tables so changes from other devices land within moments instead of
///   waiting for the next pull tick.
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  final List<SyncableTable> _syncables = [];

  /// Orders and order_items are pushed independently but order_items has no
  /// `business_id` column of its own, so it can't be registered as a plain
  /// [SyncableTable]. Instead, whenever an order row is pulled/received we
  /// also fetch its items directly. Repositories register this after
  /// construction (see [onOrderUpserted] setter) to avoid a constructor
  /// cycle: repositories depend on this service to push their writes, so
  /// this service can't depend on them up front to build its pull registry.
  Future<void> Function(String orderId)? onOrderUpserted;

  static const _log = AppLogger('sync');

  Timer? _pushTimer;
  Timer? _pullTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  RealtimeChannel? _channel;
  bool _isPushing = false;
  bool _isPulling = false;
  String? _businessId;

  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCount => _pendingCountController.stream;

  SyncService(this._db, this._supabase, this._prefs);

  /// Registers a table to be pulled and realtime-subscribed once [start] is
  /// called. Must be called before [start] (or call [start] again to
  /// re-subscribe realtime with the updated registry).
  void registerSyncable(SyncableTable table) {
    if (_syncables.any((s) => s.table == table.table)) return;
    _syncables.add(table);
  }

  void start(String businessId) {
    if (_businessId == businessId && _pushTimer != null) return;
    stop();
    _businessId = businessId;

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        triggerPush();
        triggerPull();
      }
    });

    _pushTimer = Timer.periodic(const Duration(seconds: 20), (_) => triggerPush());
    _pullTimer = Timer.periodic(const Duration(minutes: 2), (_) => triggerPull());
    _subscribeRealtime(businessId);

    triggerPush();
    triggerPull();
    _emitPendingCount();
  }

  void stop() {
    _pushTimer?.cancel();
    _pushTimer = null;
    _pullTimer?.cancel();
    _pullTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _businessId = null;
  }

  void dispose() {
    stop();
    _pendingCountController.close();
  }

  // ---------------------------------------------------------------------
  // PUSH
  // ---------------------------------------------------------------------

  /// Pushes an operation to the local queue. The UI/repositories call this
  /// instead of talking to Supabase directly.
  Future<void> queueMutation({
    required String operation, // INSERT, UPDATE, UPSERT, DELETE
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
    await _emitPendingCount();
    triggerPush();
  }

  Future<void> triggerPush() async {
    if (_isPushing) return;
    _isPushing = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.any((r) => r != ConnectivityResult.none)) return;

      final pendingOps = await (_db.select(_db.syncOperations)
            ..where((t) => t.status.equals('PENDING'))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
          .get();

      for (final op in pendingOps) {
        bool success = false;
        try {
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;

          switch (op.operation) {
            case 'INSERT':
              await _supabase.from(op.targetTable).insert(payload);
              break;
            case 'UPDATE':
              await _supabase.from(op.targetTable).update(payload).eq('id', op.recordId);
              break;
            case 'UPSERT':
              await _supabase.from(op.targetTable).upsert(payload);
              break;
            case 'DELETE':
              await _supabase.from(op.targetTable).delete().eq('id', op.recordId);
              break;
          }
          success = true;
        } catch (e, st) {
          _log.warning('Push failed for ${op.operation} ${op.targetTable}/${op.recordId}', e);
          if (op.retryCount >= 5) _log.error('Giving up on sync op ${op.id} after 5 retries', e, st);
        }

        if (success) {
          await (_db.delete(_db.syncOperations)..where((t) => t.id.equals(op.id))).go();
        } else {
          await (_db.update(_db.syncOperations)..where((t) => t.id.equals(op.id))).write(
            SyncOperationsCompanion(
              retryCount: drift.Value(op.retryCount + 1),
              status: drift.Value(op.retryCount >= 5 ? 'FAILED' : 'PENDING'),
            ),
          );
        }
      }
    } finally {
      _isPushing = false;
      await _emitPendingCount();
    }
  }

  Future<void> _emitPendingCount() async {
    if (_pendingCountController.isClosed) return;
    final count = await (_db.selectOnly(_db.syncOperations)
          ..addColumns([_db.syncOperations.id.count()])
          ..where(_db.syncOperations.status.equals('PENDING')))
        .map((row) => row.read(_db.syncOperations.id.count()) ?? 0)
        .getSingle();
    _pendingCountController.add(count);
  }

  // ---------------------------------------------------------------------
  // PULL
  // ---------------------------------------------------------------------

  String _lastPulledKey(String table, String businessId) => 'sync_pulled_${table}_$businessId';

  DateTime _lastPulledAt(String table, String businessId) {
    final raw = _prefs.getString(_lastPulledKey(table, businessId));
    return raw != null ? DateTime.parse(raw) : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _setLastPulledAt(String table, String businessId, DateTime time) {
    return _prefs.setString(_lastPulledKey(table, businessId), time.toIso8601String());
  }

  Future<void> triggerPull() async {
    final businessId = _businessId;
    if (businessId == null || _isPulling) return;
    _isPulling = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.any((r) => r != ConnectivityResult.none)) return;

      for (final syncable in _syncables) {
        try {
          await _pullTable(syncable, businessId);
        } catch (e, st) {
          _log.error('Pull failed for ${syncable.table}', e, st);
        }
      }
    } finally {
      _isPulling = false;
    }
  }

  Future<void> _pullTable(SyncableTable syncable, String businessId) async {
    final since = _lastPulledAt(syncable.table, businessId);
    final rows = await _supabase
        .from(syncable.table)
        .select()
        .eq('business_id', businessId)
        .gt(syncable.timestampColumn, since.toIso8601String())
        .order(syncable.timestampColumn);

    DateTime latest = since;
    for (final row in rows) {
      await syncable.upsertFromRemote(row);
      if (syncable.table == 'orders' && onOrderUpserted != null) {
        await onOrderUpserted!(row['id'] as String);
      }
      final ts = DateTime.tryParse(row[syncable.timestampColumn] as String? ?? '');
      if (ts != null && ts.isAfter(latest)) latest = ts;
    }

    if (rows.isNotEmpty) {
      await _setLastPulledAt(syncable.table, businessId, latest);
    }
  }

  // ---------------------------------------------------------------------
  // REALTIME
  // ---------------------------------------------------------------------

  void _subscribeRealtime(String businessId) {
    final channel = _supabase.channel('business-$businessId');

    for (final syncable in _syncables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: syncable.table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'business_id',
          value: businessId,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          if (row.isEmpty) return; // DELETE events carry no new record; we soft-delete instead
          try {
            await syncable.upsertFromRemote(row);
            if (syncable.table == 'orders' && onOrderUpserted != null) {
              await onOrderUpserted!(row['id'] as String);
            }
          } catch (e, st) {
            _log.error('Realtime merge failed for ${syncable.table}', e, st);
          }
        },
      );
    }

    channel.subscribe((status, error) {
      if (error != null) _log.error('Realtime subscription error', error);
    });
    _channel = channel;
  }
}
