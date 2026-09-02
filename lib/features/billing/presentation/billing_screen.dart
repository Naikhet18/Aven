import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/billing/widgets/checkout_dialog.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidOrdersAsync = ref.watch(unpaidOrdersStreamProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: unpaidOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: scheme.outline),
                  const SizedBox(height: 16),
                  Text('No unpaid orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.outline)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final timeString = order.createdAt != null ? DateFormat('hh:mm a').format(order.createdAt!) : '';
              final isPartiallyPaid = order.paymentStatus == 'PARTIALLY_PAID';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text('Order #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (isPartiallyPaid) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Partial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${order.orderType} • $timeString\n${order.status}',
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Currency.format(order.total, symbol: currencySymbol),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.primary),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CheckoutDialog(order: order),
                          );
                        },
                        child: const Text('Pay Now'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
