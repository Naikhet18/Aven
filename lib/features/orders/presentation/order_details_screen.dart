import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final orderDetailsProvider = FutureProvider.autoDispose.family<Order?, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrder(orderId);
});

final orderItemsDetailProvider = FutureProvider.autoDispose.family<List<OrderItem>, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrderItems(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, Order order, List<OrderItem> items) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel Order')),
        ],
      ),
    );
    if (confirmed != true) return;

    final device = ref.read(deviceIdentityProvider);
    await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, 'CANCELLED');

    try {
      await ref.read(inventoryRepositoryProvider).reverseDeductionForOrder(
            businessId: order.businessId,
            orderId: order.id,
            orderItems: items,
            deviceId: device.id,
          );
    } catch (_) {
      // Inventory reversal is best-effort.
    }

    await ref.read(auditLogServiceProvider).record(
          businessId: order.businessId,
          deviceId: device.id,
          actionType: 'CANCEL_ORDER',
          details: {'order_id': order.id, 'order_number': order.orderNumber, 'reason': reasonController.text.trim()},
        );

    ref.invalidate(orderDetailsProvider(orderId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final itemsAsync = ref.watch(orderItemsDetailProvider(orderId));
    final paymentsAsync = ref.watch(orderPaymentsProvider(orderId));
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found.'));
          final items = itemsAsync.valueOrNull ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderNumber}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Chip(label: Text(order.status)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.orderType}${order.tableNumber != null ? ' • Table ${order.tableNumber}' : ''}'
                '${order.createdAt != null ? ' • ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)}' : ''}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: items
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text('${item.quantity.toInt()}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item.itemNameSnapshot)),
                                  Text(Currency.format(item.total, symbol: currencySymbol)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _totalRow('Subtotal', order.subtotal, currencySymbol),
                      if (order.discount > 0) _totalRow('Discount', -order.discount, currencySymbol),
                      if (order.tax > 0) _totalRow('Tax', order.tax, currencySymbol),
                      const Divider(),
                      _totalRow('Total', order.total, currencySymbol, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Payments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              paymentsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                error: (_, __) => const Text('Could not load payments'),
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No payments recorded yet.'));
                  }
                  return Column(
                    children: payments
                        .map((p) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_outlined),
                              title: Text(p.paymentMethod),
                              subtitle: p.paymentTime != null ? Text(DateFormat('dd MMM, hh:mm a').format(p.paymentTime!)) : null,
                              trailing: Text(Currency.format(p.amount, symbol: currencySymbol)),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await ref.read(printerServiceProvider).printCustomerReceipt(order, items);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                        }
                      },
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Reprint Receipt'),
                    ),
                  ),
                  if (order.status != 'CANCELLED' && order.status != 'COMPLETED') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        onPressed: () => _cancelOrder(context, ref, order, items),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Order'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _totalRow(String label, double amount, String symbol, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Currency.format(amount, symbol: symbol), style: style),
        ],
      ),
    );
  }
}
