import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';

class DiscountDialog extends ConsumerStatefulWidget {
  const DiscountDialog({super.key});

  @override
  ConsumerState<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<DiscountDialog> {
  String _type = 'PERCENTAGE';
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _type = cart.discountType ?? 'PERCENTAGE';
    if (cart.discountValue > 0) _valueController.text = cart.discountValue.toString();
    _reasonController.text = cart.discountReason ?? '';
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PERCENTAGE', label: Text('Percent %')),
              ButtonSegment(value: 'FIXED', label: Text('Fixed ₹')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _type == 'PERCENTAGE' ? 'Discount %' : 'Discount amount',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        if (ref.watch(cartProvider).discountType != null)
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearDiscount();
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_valueController.text) ?? 0;
            if (value <= 0) {
              Navigator.of(context).pop();
              return;
            }
            ref.read(cartProvider.notifier).applyDiscount(
                  type: _type,
                  value: value,
                  reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
                );
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
