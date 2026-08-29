import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';
import 'package:intl/intl.dart';

final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId == null) return [];
  return repo.getOrders(businessId);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersListProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Order #${order.orderNumber} - ${order.orderType}'),
                  subtitle: Text(
                    '${order.status} • ${Currency.format(order.total, symbol: currencySymbol)}\n'
                    '${order.createdAt != null ? DateFormat('dd MMM, hh:mm a').format(order.createdAt!) : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(order.paymentStatus),
                    backgroundColor: order.paymentStatus == 'PAID'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                  onTap: () => context.go('/orders/${order.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
