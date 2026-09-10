import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/add_ingredient_dialog.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/adjust_stock_dialog.dart';
import 'package:khao_piyo_pos/features/inventory/widgets/recipe_editor_dialog.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/widgets/pressable_scale.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF040404),
        appBar: AppBar(
          title: const Text('Inventory'),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            tabs: const [
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
            label: const Text('Ingredient', style: TextStyle(fontWeight: FontWeight.bold)),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, _) => const Center(child: Text('Failed to load ingredients.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
      data: (ingredients) {
        if (ingredients.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24)
                    .animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 16),
                const Text('No ingredients yet.', style: TextStyle(color: Colors.white54, fontSize: 18))
                    .animate().fade(delay: 100.ms),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () async => ref.invalidate(ingredientsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: ingredients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              return _IngredientTile(ingredient: ingredient)
                  .animate()
                  .fade(delay: (index * 30).ms, duration: 400.ms)
                  .slideY(begin: 0.1, delay: (index * 30).ms);
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
    final isLowStock = ingredient.isLowStock;
    final warningColor = const Color(0xFFF91133); // Red
    final goodColor = const Color(0xFF34C759); // Green

    return PressableScale(
      onTap: () => showDialog(context: context, builder: (_) => AdjustStockDialog(ingredient: ingredient)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: isLowStock ? Border.all(color: warningColor.withValues(alpha: 0.3), width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isLowStock) ...[
                        Icon(Icons.warning_amber_rounded, color: warningColor, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'Alert at ${ingredient.lowStockThreshold} ${ingredient.unit}',
                        style: TextStyle(
                          color: isLowStock ? warningColor : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ingredient.currentStock}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isLowStock ? warningColor : goodColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  ingredient.unit.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.0),
                ),
              ],
            ),
          ],
        ),
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, _) => const Center(child: Text('Failed to load recipes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
      data: (state) {
        if (state.menuItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 64, color: Colors.white24)
                    .animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 16),
                const Text('Add menu items to define recipes.', style: TextStyle(color: Colors.white54, fontSize: 18))
                    .animate().fade(delay: 100.ms),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: state.menuItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = state.menuItems[index];
            return PressableScale(
              onTap: () => showDialog(context: context, builder: (_) => RecipeEditorDialog(menuItem: item)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: -0.2),
                    ),
                    const Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
                  ],
                ),
              ),
            ).animate().fade(delay: (index * 30).ms, duration: 400.ms).slideY(begin: 0.1, delay: (index * 30).ms);
          },
        );
      },
    );
  }
}
