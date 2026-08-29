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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Checkout'),
      ),
      backgroundColor: Colors.grey.shade100,
      body: unpaidOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No unpaid orders.',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final timeString = order.createdAt != null 
                  ? DateFormat('hh:mm a').format(order.createdAt!) 
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${order.orderType} • $timeString\nStatus: ${order.status} • ${order.paymentStatus}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Currency.format(order.total, symbol: currencySymbol),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CheckoutDialog(order: order),
                          );
                        },
                        child: const Text('PAY NOW'),
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
