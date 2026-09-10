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
  final asyncOrders = ref.watch(activeOrdersStreamProvider);
  final activeOrders = asyncOrders.valueOrNull;

  if (activeOrders == null) {
    // If we have no data yet, await the future to show loading.
    final initialOrders = await ref.watch(activeOrdersStreamProvider.future);
    return _fetchItemsForOrders(ref, initialOrders);
  }

  // We have the latest orders, fetch their items. 
  // Because it's a FutureProvider, Riverpod automatically preserves the previous state 
  // in the UI while this async operation runs.
  return _fetchItemsForOrders(ref, activeOrders);
});

Future<List<OrderWithItems>> _fetchItemsForOrders(Ref ref, List<Order> orders) async {
  final repo = ref.read(orderRepositoryProvider);
  final ordersWithItems = <OrderWithItems>[];
  for (final order in orders) {
    final items = await repo.getOrderItems(order.id);
    ordersWithItems.add(OrderWithItems(order: order, items: items));
  }
  return ordersWithItems;
}
