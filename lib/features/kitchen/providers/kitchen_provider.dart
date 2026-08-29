import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class OrderWithItems {
  final Order order;
  final List<OrderItem> items;

  OrderWithItems({required this.order, required this.items});
}

final activeOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId == null) return const Stream.empty();
  return repo.watchActiveOrders(businessId);
});

final activeOrdersWithItemsProvider = FutureProvider<List<OrderWithItems>>((ref) async {
  // Watch the stream of active orders
  final activeOrders = await ref.watch(activeOrdersStreamProvider.future);
  final repo = ref.read(orderRepositoryProvider);
  
  // For each order, fetch its items
  final ordersWithItems = <OrderWithItems>[];
  for (final order in activeOrders) {
    final items = await repo.getOrderItems(order.id);
    ordersWithItems.add(OrderWithItems(order: order, items: items));
  }
  
  return ordersWithItems;
});
