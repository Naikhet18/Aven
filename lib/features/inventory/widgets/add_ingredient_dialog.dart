import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AddIngredientDialog extends ConsumerStatefulWidget {
  const AddIngredientDialog({super.key});

  @override
  ConsumerState<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends ConsumerState<AddIngredientDialog> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;

    final ingredient = Ingredient(
      id: const Uuid().v4(),
      businessId: businessId,
      name: _nameController.text.trim(),
      unit: _unitController.text.trim().isEmpty ? 'unit' : _unitController.text.trim(),
      currentStock: double.tryParse(_stockController.text) ?? 0,
      lowStockThreshold: double.tryParse(_thresholdController.text) ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(inventoryRepositoryProvider).addIngredient(ingredient);
    ref.invalidate(ingredientsProvider);
    ref.invalidate(lowStockIngredientsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(labelText: 'Unit (kg, g, liter, piece...)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Starting stock', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Low-stock alert at', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
