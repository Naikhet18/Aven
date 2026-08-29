import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersWithItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System (KDS)'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade200,
      body: activeOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (ordersWithItems) {
          if (ordersWithItems.isEmpty) {
            return const Center(
              child: Text(
                'No active orders.',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 400, // Fixed height for ticket consistency
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: ordersWithItems.length,
            itemBuilder: (context, index) {
              final orderData = ordersWithItems[index];
              return _OrderTicket(orderData: orderData);
            },
          );
        },
      ),
    );
  }
}

class _OrderTicket extends ConsumerWidget {
  final OrderWithItems orderData;

  const _OrderTicket({required this.orderData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = orderData.order;
    final items = orderData.items;
    
    // Determine header color based on status
    final headerColor = order.status == 'NEW' 
        ? Colors.blue.shade700 
        : Colors.orange.shade700;

    // Calculate time elapsed
    final timeElapsed = order.createdAt != null 
        ? DateTime.now().difference(order.createdAt!).inMinutes 
        : 0;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ticket Header
          Container(
            color: headerColor,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderType,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$timeElapsed min',
                      style: TextStyle(
                        color: timeElapsed > 15 ? Colors.red.shade100 : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                      Text(
                        'Table ${order.tableNumber}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemNameSnapshot,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                'Note: ${item.notes}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: order.status == 'NEW' 
                      ? Colors.orange.shade700 
                      : Colors.green.shade700,
                ),
                onPressed: () async {
                  final repo = ref.read(orderRepositoryProvider);
                  final nextStatus = order.status == 'NEW' ? 'PREPARING' : 'READY';
                  await repo.updateOrderStatus(order.id, nextStatus);
                  // The stream provider will auto-refresh the UI
                },
                child: Text(
                  order.status == 'NEW' ? 'START PREPARING' : 'MARK READY',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
