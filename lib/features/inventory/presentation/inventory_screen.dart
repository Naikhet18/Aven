import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/add_ingredient_dialog.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/adjust_stock_dialog.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/recipe_editor_dialog.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Stock'),
              Tab(text: 'Recipes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_StockTab(), _RecipesTab()],
        ),
        floatingActionButton: Builder(builder: (context) {
          final isStockTab = DefaultTabController.of(context).index == 0;
          if (!isStockTab) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => showDialog(context: context, builder: (_) => const AddIngredientDialog()),
            icon: const Icon(Icons.add),
            label: const Text('Ingredient'),
          );
        }),
      ),
    );
  }
}

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return ingredientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (ingredients) {
        if (ingredients.isEmpty) {
          return const Center(child: Text('No ingredients yet. Add one to start tracking stock.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ingredientsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              return _IngredientTile(ingredient: ingredient);
            },
          ),
        );
      },
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ingredient.isLowStock ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        title: Text(ingredient.name),
        subtitle: Text('Low-stock alert at ${ingredient.lowStockThreshold} ${ingredient.unit}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${ingredient.currentStock} ${ingredient.unit}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: ingredient.isLowStock ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            if (ingredient.isLowStock)
              Text('LOW STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
          ],
        ),
        onTap: () => showDialog(context: context, builder: (_) => AdjustStockDialog(ingredient: ingredient)),
      ),
    );
  }
}

class _RecipesTab extends ConsumerWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuStateAsync = ref.watch(menuProvider);

    return menuStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (state) {
        if (state.menuItems.isEmpty) {
          return const Center(child: Text('Add menu items first to define their recipes.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: state.menuItems.length,
          itemBuilder: (context, index) {
            final item = state.menuItems[index];
            return Card(
              child: ListTile(
                title: Text(item.name),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => showDialog(context: context, builder: (_) => RecipeEditorDialog(menuItem: item)),
              ),
            );
          },
        );
      },
    );
  }
}
