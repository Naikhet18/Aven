import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF91133)),
            onPressed: () => Navigator.of(context).pop(true), 
            child: const Text('Cancel Order')
          ),
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
      backgroundColor: const Color(0xFF040404),
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found.', style: TextStyle(color: Colors.white)));
          final items = itemsAsync.valueOrNull ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderNumber}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(order.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 8),
              
              Text(
                '${order.orderType}${order.tableNumber != null ? ' • Table ${order.tableNumber}' : ''}'
                '${order.createdAt != null ? ' • ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)}' : ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600),
              ).animate().fade(delay: 100.ms),
              
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: items
                      .map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${item.quantity.toInt()}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Text(item.itemNameSnapshot, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600))),
                                Text(Currency.format(item.total, symbol: currencySymbol), style: const TextStyle(fontSize: 16, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _totalRow('Subtotal', order.subtotal, currencySymbol),
                    if (order.discount > 0) _totalRow('Discount', -order.discount, currencySymbol, color: const Color(0xFF34C759)),
                    if (order.tax > 0) _totalRow('Tax', order.tax, currencySymbol),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _totalRow('Total', order.total, currencySymbol, bold: true, size: 24),
                  ],
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),
              
              const Text('Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                  .animate().fade(delay: 400.ms),
              const SizedBox(height: 12),

              paymentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                error: (_, _) => const Text('Could not load payments', style: TextStyle(color: Colors.white54)),
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Text('No payments recorded yet.', style: TextStyle(color: Colors.white54));
                  }
                  return Column(
                    children: payments
                        .map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments_outlined, color: Color(0xFF34C759), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.paymentMethod, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                                    if (p.paymentTime != null)
                                      Text(DateFormat('dd MMM, hh:mm a').format(p.paymentTime!), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(Currency.format(p.amount, symbol: currencySymbol), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()])),
                            ],
                          ),
                        )).toList(),
                  );
                },
              ).animate().fade(delay: 450.ms),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: () async {
                        final result = await ref.read(printerServiceProvider).printCustomerReceipt(order, items);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                        }
                      },
                      icon: const Icon(Icons.print_outlined, color: Colors.white),
                      label: const Text('Reprint', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (order.status != 'CANCELLED' && order.status != 'COMPLETED') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: Color(0xFFF91133)),
                          backgroundColor: const Color(0xFFF91133).withValues(alpha: 0.1),
                        ),
                        onPressed: () => _cancelOrder(context, ref, order, items),
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFF91133)),
                        label: const Text('Cancel', style: TextStyle(color: Color(0xFFF91133), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
            ],
          );
        },
      ),
    );
  }

  Widget _totalRow(String label, double amount, String symbol, {bool bold = false, double size = 16, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600, 
      fontSize: size, 
      color: color ?? (bold ? Colors.white : Colors.white70),
      fontFeatures: const [FontFeature.tabularFigures()]
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
