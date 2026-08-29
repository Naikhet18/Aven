import 'package:khao_piyo_pos/shared/models/category.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';

abstract class MenuRepository {
  Future<List<Category>> getCategories(String businessId);
  Future<List<Category>> getCategoriesSince(String businessId, DateTime since);
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> upsertCategory(Category category);
  Future<void> deleteCategory(String categoryId);

  Future<List<MenuItem>> getMenuItems(String businessId);
  Future<List<MenuItem>> getMenuItemsSince(String businessId, DateTime since);
  Future<void> addMenuItem(MenuItem item);
  Future<void> updateMenuItem(MenuItem item);
  Future<void> upsertMenuItem(MenuItem item);
  Future<void> deleteMenuItem(String itemId);
}
