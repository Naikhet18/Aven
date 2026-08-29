import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';

class CheckoutDialog extends ConsumerWidget {
  final Order order;

  const CheckoutDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Checkout Order #${order.orderNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total Amount',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text('Select Payment Method:'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _processPayment(context, ref, 'CASH'),
            icon: const Icon(Icons.money),
            label: const Text('CASH'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _processPayment(context, ref, 'UPI'),
            icon: const Icon(Icons.qr_code),
            label: const Text('UPI'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _processPayment(context, ref, 'CARD'),
            icon: const Icon(Icons.credit_card),
            label: const Text('CARD'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref, String method) async {
    final success = await ref.read(billingProvider.notifier).checkoutOrder(order.id, method);
    
    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${order.orderNumber} paid via $method!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process payment. Please try again.')),
        );
      }
    }
  }
}
