import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/category.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class MenuState {
  final List<Category> categories;
  final List<MenuItem> menuItems;

  MenuState({this.categories = const [], this.menuItems = const []});

  MenuState copyWith({
    List<Category>? categories,
    List<MenuItem>? menuItems,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}

class MenuNotifier extends AsyncNotifier<MenuState> {
  @override
  Future<MenuState> build() async {
    return _loadData();
  }

  Future<MenuState> _loadData() async {
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(menuRepositoryProvider);
    
    if (businessId == null) return MenuState();
    final categories = await repo.getCategories(businessId);
    final items = await repo.getMenuItems(businessId);
    
    return MenuState(categories: categories, menuItems: items);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> addCategory(Category category) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.addCategory(category);
    await reload();
  }

  Future<void> updateCategory(Category category) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.updateCategory(category);
    await reload();
  }

  Future<void> deleteCategory(String categoryId) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.deleteCategory(categoryId);
    await reload();
  }

  Future<void> addMenuItem(MenuItem item) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.addMenuItem(item);
    await reload();
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.updateMenuItem(item);
    await reload();
  }

  Future<void> deleteMenuItem(String itemId) async {
    final repo = ref.read(menuRepositoryProvider);
    await repo.deleteMenuItem(itemId);
    await reload();
  }
}

final menuProvider = AsyncNotifierProvider<MenuNotifier, MenuState>(() {
  return MenuNotifier();
});
