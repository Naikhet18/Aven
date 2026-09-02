import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/models/recipe.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class _RecipeLine {
  String ingredientId;
  double quantity;
  _RecipeLine(this.ingredientId, this.quantity);
}

/// Edits the bill-of-materials for a single menu item: which ingredients
/// (and how much of each) get deducted from stock every time this item is
/// sold. A menu item with no lines here simply isn't tracked in inventory.
class RecipeEditorDialog extends ConsumerStatefulWidget {
  final MenuItem menuItem;
  const RecipeEditorDialog({super.key, required this.menuItem});

  @override
  ConsumerState<RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends ConsumerState<RecipeEditorDialog> {
  List<_RecipeLine> _lines = [];
  List<Ingredient> _ingredients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final businessId = ref.read(currentBusinessIdProvider)!;
    final repo = ref.read(inventoryRepositoryProvider);
    final ingredients = await repo.getIngredients(businessId);
    final existing = await repo.getRecipeForMenuItem(widget.menuItem.id);
    setState(() {
      _ingredients = ingredients;
      _lines = existing.map((r) => _RecipeLine(r.ingredientId, r.quantityRequired)).toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final validLines = _lines.where((l) => l.quantity > 0).toList();
    final recipes = validLines
        .map((l) => Recipe(id: const Uuid().v4(), menuItemId: widget.menuItem.id, ingredientId: l.ingredientId, quantityRequired: l.quantity))
        .toList();
    await ref.read(inventoryRepositoryProvider).setRecipe(widget.menuItem.id, recipes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Recipe: ${widget.menuItem.name}'),
      content: SizedBox(
        width: 380,
        child: _loading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : _ingredients.isEmpty
                ? const Text('Add ingredients first (Inventory > Stock tab) before defining a recipe.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._lines.asMap().entries.map((entry) {
                        final index = entry.key;
                        final line = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: line.ingredientId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(isDense: true),
                                  items: _ingredients
                                      .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (val) => setState(() => line.ingredientId = val!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, hintText: 'Qty'),
                                  onChanged: (val) => line.quantity = double.tryParse(val) ?? 0,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove ingredient',
                                onPressed: () => setState(() => _lines.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setState(() => _lines.add(_RecipeLine(_ingredients.first.id, 0))),
                        icon: const Icon(Icons.add),
                        label: const Text('Add ingredient'),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _loading ? null : _save, child: const Text('Save Recipe')),
      ],
    );
  }
}
