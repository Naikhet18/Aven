import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/shared/models/audit_log.dart';

/// Records who-did-what for sensitive actions (cancellations, refunds,
/// manual stock adjustments, price changes) so a business owner can review
/// them later -- separate from the app's regular data tables since audit
/// rows are never edited or deleted, only appended and read.
class AuditLogService {
  final AppDatabase _db;
  final SyncService _syncService;

  AuditLogService(this._db, this._syncService);

  Future<void> record({
    required String businessId,
    required String deviceId,
    required String actionType,
    Map<String, dynamic>? details,
  }) async {
    final log = AuditLog(
      id: const Uuid().v4(),
      businessId: businessId,
      deviceId: deviceId,
      actionType: actionType,
      details: details == null ? null : jsonEncode(details),
      createdAt: DateTime.now(),
    );

    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
          id: log.id,
          businessId: log.businessId,
          deviceId: Value(log.deviceId),
          actionType: log.actionType,
          details: Value(log.details),
          createdAt: Value(log.createdAt),
        ));

    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'audit_logs',
      recordId: log.id,
      payload: log.toJson(),
    );
  }

  /// Merges an audit log pulled/received from Supabase without re-queueing a push.
  Future<void> upsertFromRemote(AuditLog log) async {
    await _db.into(_db.auditLogs).insertOnConflictUpdate(AuditLogsCompanion.insert(
          id: log.id,
          businessId: log.businessId,
          deviceId: Value(log.deviceId),
          actionType: log.actionType,
          details: Value(log.details),
          createdAt: Value(log.createdAt),
        ));
  }

  Future<List<AuditLog>> getRecent(String businessId, {int limit = 100}) async {
    final query = _db.select(_db.auditLogs)
      ..where((a) => a.businessId.equals(businessId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);
    final result = await query.get();
    return result
        .map((e) => AuditLog(
              id: e.id,
              businessId: e.businessId,
              deviceId: e.deviceId,
              actionType: e.actionType,
              details: e.details,
              createdAt: e.createdAt,
            ))
        .toList();
  }
}
