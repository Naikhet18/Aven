import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/features/menu/repository/menu_repository.dart';
import 'package:khao_piyo_pos/shared/models/category.dart' as domain;
import 'package:khao_piyo_pos/shared/models/menu_item.dart' as domain;

class LocalMenuRepository implements MenuRepository {
  final AppDatabase _db;

  LocalMenuRepository(this._db);

  @override
  Future<List<domain.Category>> getCategories(String businessId) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.businessId.equals(businessId) & c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    
    final result = await query.get();
    return result.map((e) => domain.Category(
      id: e.id,
      businessId: e.businessId,
      name: e.name,
      sortOrder: e.sortOrder,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      deletedAt: e.deletedAt,
    )).toList();
  }

  @override
  Future<List<domain.MenuItem>> getMenuItems(String businessId) async {
    final query = _db.select(_db.menuItems)
      ..where((m) => m.businessId.equals(businessId) & m.deletedAt.isNull())
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]);
    
    final result = await query.get();
    return result.map((e) => domain.MenuItem(
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
    )).toList();
  }

  @override
  Future<void> addCategory(domain.Category category) async {
    await _db.into(_db.categories).insert(
      CategoryEntity(
        id: category.id,
        businessId: category.businessId,
        name: category.name,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        deletedAt: category.deletedAt,
      ),
    );
  }

  @override
  Future<void> updateCategory(domain.Category category) async {
    await _db.update(_db.categories).replace(
      CategoryEntity(
        id: category.id,
        businessId: category.businessId,
        name: category.name,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        deletedAt: category.deletedAt,
      ),
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // Soft delete
    await (_db.update(_db.categories)..where((c) => c.id.equals(categoryId)))
        .write(CategoriesCompanion(deletedAt: Value(DateTime.now())));
  }

  @override
  Future<void> addMenuItem(domain.MenuItem item) async {
    await _db.into(_db.menuItems).insert(
      MenuItemEntity(
        id: item.id,
        businessId: item.businessId,
        categoryId: item.categoryId,
        name: item.name,
        price: item.price,
        isAvailable: item.isAvailable,
        sortOrder: item.sortOrder,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        deletedAt: item.deletedAt,
      ),
    );
  }

  @override
  Future<void> updateMenuItem(domain.MenuItem item) async {
    await _db.update(_db.menuItems).replace(
      MenuItemEntity(
        id: item.id,
        businessId: item.businessId,
        categoryId: item.categoryId,
        name: item.name,
        price: item.price,
        isAvailable: item.isAvailable,
        sortOrder: item.sortOrder,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        deletedAt: item.deletedAt,
      ),
    );
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    // Soft delete
    await (_db.update(_db.menuItems)..where((m) => m.id.equals(itemId)))
        .write(MenuItemsCompanion(deletedAt: Value(DateTime.now())));
  }

  @override
  Future<List<domain.Category>> getCategoriesSince(String businessId, DateTime since) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.businessId.equals(businessId) & c.updatedAt.isBiggerThanValue(since))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    
    final result = await query.get();
    return result.map((e) => domain.Category(
      id: e.id,
      businessId: e.businessId,
      name: e.name,
      sortOrder: e.sortOrder,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      deletedAt: e.deletedAt,
    )).toList();
  }

  @override
  Future<void> upsertCategory(domain.Category category) async {
    await _db.into(_db.categories).insertOnConflictUpdate(
      CategoryEntity(
        id: category.id,
        businessId: category.businessId,
        name: category.name,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        deletedAt: category.deletedAt,
      ),
    );
  }

  @override
  Future<List<domain.MenuItem>> getMenuItemsSince(String businessId, DateTime since) async {
    final query = _db.select(_db.menuItems)
      ..where((m) => m.businessId.equals(businessId) & m.updatedAt.isBiggerThanValue(since))
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]);
    
    final result = await query.get();
    return result.map((e) => domain.MenuItem(
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
    )).toList();
  }

  @override
  Future<void> upsertMenuItem(domain.MenuItem item) async {
    await _db.into(_db.menuItems).insertOnConflictUpdate(
      MenuItemEntity(
        id: item.id,
        businessId: item.businessId,
        categoryId: item.categoryId,
        name: item.name,
        price: item.price,
        isAvailable: item.isAvailable,
        sortOrder: item.sortOrder,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        deletedAt: item.deletedAt,
      ),
    );
  }
}
