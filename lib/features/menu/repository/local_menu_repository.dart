import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/menu/repository/menu_repository.dart';
import 'package:khao_piyo_pos/shared/models/category.dart' as domain;
import 'package:khao_piyo_pos/shared/models/menu_item.dart' as domain;

class LocalMenuRepository implements MenuRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalMenuRepository(this._db, this._syncService);

  @override
  Future<List<domain.Category>> getCategories(String businessId) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.businessId.equals(businessId) & c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);

    final result = await query.get();
    return result.map(_mapCategoryFromDb).toList();
  }

  @override
  Future<List<domain.MenuItem>> getMenuItems(String businessId) async {
    final query = _db.select(_db.menuItems)
      ..where((m) => m.businessId.equals(businessId) & m.deletedAt.isNull())
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]);

    final result = await query.get();
    return result.map(_mapMenuItemFromDb).toList();
  }

  @override
  Future<void> addCategory(domain.Category category) async {
    await _db.into(_db.categories).insert(_categoryCompanion(category));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'categories',
      recordId: category.id,
      payload: category.toJson(),
    );
  }

  @override
  Future<void> updateCategory(domain.Category category) async {
    await _db.update(_db.categories).replace(_categoryEntity(category));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'categories',
      recordId: category.id,
      payload: category.toJson(),
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final deletedAt = DateTime.now();
    await (_db.update(_db.categories)..where((c) => c.id.equals(categoryId)))
        .write(CategoriesCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'categories',
      recordId: categoryId,
      payload: {'deleted_at': deletedAt.toIso8601String(), 'updated_at': deletedAt.toIso8601String()},
    );
  }

  @override
  Future<void> addMenuItem(domain.MenuItem item) async {
    await _db.into(_db.menuItems).insert(_menuItemCompanion(item));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'menu_items',
      recordId: item.id,
      payload: item.toJson(),
    );
  }

  @override
  Future<void> updateMenuItem(domain.MenuItem item) async {
    await _db.update(_db.menuItems).replace(_menuItemEntity(item));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'menu_items',
      recordId: item.id,
      payload: item.toJson(),
    );
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    final deletedAt = DateTime.now();
    await (_db.update(_db.menuItems)..where((m) => m.id.equals(itemId)))
        .write(MenuItemsCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'menu_items',
      recordId: itemId,
      payload: {'deleted_at': deletedAt.toIso8601String(), 'updated_at': deletedAt.toIso8601String()},
    );
  }

  @override
  Future<List<domain.Category>> getCategoriesSince(String businessId, DateTime since) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.businessId.equals(businessId) & c.updatedAt.isBiggerThanValue(since))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);

    final result = await query.get();
    return result.map(_mapCategoryFromDb).toList();
  }

  @override
  Future<void> upsertCategory(domain.Category category) async {
    await _db.into(_db.categories).insertOnConflictUpdate(_categoryEntity(category));
    await _syncService.queueMutation(
      operation: 'UPSERT',
      targetTable: 'categories',
      recordId: category.id,
      payload: category.toJson(),
    );
  }

  /// Merges a category pulled/received from Supabase without re-queueing a push.
  Future<void> upsertCategoryFromRemote(domain.Category category) async {
    await _db.into(_db.categories).insertOnConflictUpdate(_categoryEntity(category));
  }

  @override
  Future<List<domain.MenuItem>> getMenuItemsSince(String businessId, DateTime since) async {
    final query = _db.select(_db.menuItems)
      ..where((m) => m.businessId.equals(businessId) & m.updatedAt.isBiggerThanValue(since))
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]);

    final result = await query.get();
    return result.map(_mapMenuItemFromDb).toList();
  }

  @override
  Future<void> upsertMenuItem(domain.MenuItem item) async {
    await _db.into(_db.menuItems).insertOnConflictUpdate(_menuItemEntity(item));
    await _syncService.queueMutation(
      operation: 'UPSERT',
      targetTable: 'menu_items',
      recordId: item.id,
      payload: item.toJson(),
    );
  }

  /// Merges a menu item pulled/received from Supabase without re-queueing a push.
  Future<void> upsertMenuItemFromRemote(domain.MenuItem item) async {
    await _db.into(_db.menuItems).insertOnConflictUpdate(_menuItemEntity(item));
  }

  // --- Mappers ---

  domain.Category _mapCategoryFromDb(CategoryEntity e) => domain.Category(
        id: e.id,
        businessId: e.businessId,
        name: e.name,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );

  CategoryEntity _categoryEntity(domain.Category c) => CategoryEntity(
        id: c.id,
        businessId: c.businessId,
        name: c.name,
        sortOrder: c.sortOrder,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        deletedAt: c.deletedAt,
      );

  CategoriesCompanion _categoryCompanion(domain.Category c) => CategoriesCompanion.insert(
        id: c.id,
        businessId: c.businessId,
        name: c.name,
        sortOrder: Value(c.sortOrder),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
        deletedAt: Value(c.deletedAt),
      );

  domain.MenuItem _mapMenuItemFromDb(MenuItemEntity e) => domain.MenuItem(
        id: e.id,
        businessId: e.businessId,
        categoryId: e.categoryId,
        name: e.name,
        price: e.price,
        isAvailable: e.isAvailable,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );

  MenuItemEntity _menuItemEntity(domain.MenuItem i) => MenuItemEntity(
        id: i.id,
        businessId: i.businessId,
        categoryId: i.categoryId,
        name: i.name,
        price: i.price,
        isAvailable: i.isAvailable,
        sortOrder: i.sortOrder,
        createdAt: i.createdAt,
        updatedAt: i.updatedAt,
        deletedAt: i.deletedAt,
      );

  MenuItemsCompanion _menuItemCompanion(domain.MenuItem i) => MenuItemsCompanion.insert(
        id: i.id,
        businessId: i.businessId,
        categoryId: i.categoryId,
        name: i.name,
        price: i.price,
        isAvailable: Value(i.isAvailable),
        sortOrder: Value(i.sortOrder),
        createdAt: Value(i.createdAt),
        updatedAt: Value(i.updatedAt),
        deletedAt: Value(i.deletedAt),
      );
}
