import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/recipe_editor_dialog.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';
import 'package:khao_piyo_pos/features/menu/widgets/add_category_dialog.dart';
import 'package:khao_piyo_pos/features/menu/widgets/add_menu_item_sheet.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuStateAsync = ref.watch(menuProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(menuProvider.notifier).reload(),
          ),
        ],
      ),
      body: menuStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => const Center(child: Text('Failed to load menu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
        data: (state) {
          if (state.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No categories found. Start by adding one.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddCategoryDialog(context),
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: state.categories.length,
            child: Column(
              children: [
                Container(
                  color: AppTheme.surfaceLow,
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabs: state.categories
                              .map((c) => Tab(text: c.name))
                              .toList(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Category',
                        onPressed: () => _showAddCategoryDialog(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: state.categories.map((category) {
                      final categoryItems = state.menuItems
                          .where((item) => item.categoryId == category.id)
                          .toList();

                      return ListView.separated(
                        itemCount: categoryItems.length + 1,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (context, index) {
                          if (index == categoryItems.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddMenuItemSheet(context, ref, category.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            );
                          }

                          final item = categoryItems[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            subtitle: Text(Currency.format(item.price, symbol: currencySymbol), style: const TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.set_meal_outlined, color: Colors.white54),
                                  tooltip: 'Edit recipe',
                                  onPressed: () => showDialog(context: context, builder: (_) => RecipeEditorDialog(menuItem: item)),
                                ),
                                Switch(
                                  value: item.isAvailable,
                                  activeThumbColor: AppTheme.success,
                                  onChanged: (val) {
                                    final updated = item.copyWith(isAvailable: val);
                                    ref.read(menuProvider.notifier).updateMenuItem(updated);
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _showAddMenuItemSheet(context, ref, category.id, itemToEdit: item),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  void _showAddMenuItemSheet(BuildContext context, WidgetRef ref, String categoryId, {MenuItem? itemToEdit}) {
    final state = ref.read(menuProvider).valueOrNull;
    if (state == null) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => AddMenuItemSheet(
        categories: state.categories,
        defaultCategoryId: categoryId,
        itemToEdit: itemToEdit,
      ),
    );
  }
}
