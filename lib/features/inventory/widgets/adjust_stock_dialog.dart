import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/models/inventory_transaction.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AdjustStockDialog extends ConsumerStatefulWidget {
  final Ingredient ingredient;
  const AdjustStockDialog({super.key, required this.ingredient});

  @override
  ConsumerState<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<AdjustStockDialog> {
  String _type = 'PURCHASE';
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return;

    setState(() => _isSaving = true);
    final businessId = ref.read(currentBusinessIdProvider);
    final device = ref.read(deviceIdentityProvider);
    if (businessId == null) return;

    final signedQty = _type == 'WASTAGE' ? -qty : qty; // PURCHASE/MANUAL_ADJUSTMENT add stock, WASTAGE removes it

    await ref.read(inventoryRepositoryProvider).recordTransaction(InventoryTransaction(
          id: const Uuid().v4(),
          businessId: businessId,
          ingredientId: widget.ingredient.id,
          transactionType: _type,
          quantityChange: signedQty,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: DateTime.now(),
          createdByDevice: device.id,
        ));

    ref.invalidate(ingredientsProvider);
    ref.invalidate(lowStockIngredientsProvider);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock: ${widget.ingredient.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Current stock: ${widget.ingredient.currentStock} ${widget.ingredient.unit}'),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PURCHASE', label: Text('Purchase')),
              ButtonSegment(value: 'WASTAGE', label: Text('Wastage')),
              ButtonSegment(value: 'MANUAL_ADJUSTMENT', label: Text('Adjust')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Quantity (${widget.ingredient.unit})', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
