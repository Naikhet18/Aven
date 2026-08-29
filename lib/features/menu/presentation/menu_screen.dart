import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';
import 'package:khao_piyo_pos/features/menu/widgets/add_category_dialog.dart';
import 'package:khao_piyo_pos/features/menu/widgets/add_menu_item_sheet.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuStateAsync = ref.watch(menuProvider);

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
                  color: Theme.of(context).cardColor,
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

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: categoryItems.length + 1,
                        itemBuilder: (context, index) {
                          if (index == categoryItems.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddMenuItemSheet(
                                    context, ref, category.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            );
                          }

                          final item = categoryItems[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                              trailing: Switch(
                                value: item.isAvailable,
                                onChanged: (val) {
                                  final updated = item.copyWith(isAvailable: val);
                                  ref.read(menuProvider.notifier).updateMenuItem(updated);
                                },
                              ),
                              onTap: () => _showAddMenuItemSheet(context, ref, category.id, itemToEdit: item),
                            ),
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

  void _showAddMenuItemSheet(BuildContext context, WidgetRef ref, String categoryId, {itemToEdit}) {
    final state = ref.read(menuProvider).valueOrNull;
    if (state == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddMenuItemSheet(
        categories: state.categories,
        defaultCategoryId: categoryId,
        itemToEdit: itemToEdit,
      ),
    );
  }
}
