import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/tables/repository/table_repository.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart' as domain;

class LocalTableRepository implements TableRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalTableRepository(this._db, this._syncService);

  @override
  Future<List<domain.RestaurantTable>> getTables(String businessId) async {
    final query = _db.select(_db.tables)
      ..where((t) => t.businessId.equals(businessId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final result = await query.get();
    return result.map(_mapFromDb).toList();
  }

  @override
  Future<void> addTable(domain.RestaurantTable table) async {
    await _db.into(_db.tables).insert(_companion(table));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'tables',
      recordId: table.id,
      payload: table.toJson(),
    );
  }

  @override
  Future<void> updateTable(domain.RestaurantTable table) async {
    await _db.update(_db.tables).replace(_entity(table));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'tables',
      recordId: table.id,
      payload: table.toJson(),
    );
  }

  @override
  Future<void> deleteTable(String tableId) async {
    final deletedAt = DateTime.now();
    await (_db.update(_db.tables)..where((t) => t.id.equals(tableId)))
        .write(TablesCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'tables',
      recordId: tableId,
      payload: {'deleted_at': deletedAt.toIso8601String(), 'updated_at': deletedAt.toIso8601String()},
    );
  }

  /// Merges a table pulled/received from Supabase without re-queueing a push.
  Future<void> upsertTableFromRemote(domain.RestaurantTable table) async {
    await _db.into(_db.tables).insertOnConflictUpdate(_entity(table));
  }

  domain.RestaurantTable _mapFromDb(RestaurantTableEntity e) => domain.RestaurantTable(
        id: e.id,
        businessId: e.businessId,
        name: e.name,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );

  RestaurantTableEntity _entity(domain.RestaurantTable t) => RestaurantTableEntity(
        id: t.id,
        businessId: t.businessId,
        name: t.name,
        sortOrder: t.sortOrder,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
        deletedAt: t.deletedAt,
      );

  TablesCompanion _companion(domain.RestaurantTable t) => TablesCompanion.insert(
        id: t.id,
        businessId: t.businessId,
        name: t.name,
        sortOrder: Value(t.sortOrder),
        createdAt: Value(t.createdAt),
        updatedAt: Value(t.updatedAt),
        deletedAt: Value(t.deletedAt),
      );
}
