import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class DailyReport {
  final double totalRevenue;
  final int totalOrders;
  final List<TopItem> topItems;
  final List<Order> rawOrders; // Kept for export purposes

  DailyReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.topItems,
    required this.rawOrders,
  });
}

class TopItem {
  final String name;
  final double quantity;
  final double revenue;

  TopItem({required this.name, required this.quantity, required this.revenue});
}

final dailyReportProvider = FutureProvider<DailyReport>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) {
    return DailyReport(totalRevenue: 0, totalOrders: 0, topItems: [], rawOrders: []);
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  // Fetch completed orders for today
  final allOrders = await orderRepo.getOrdersByDateRange(businessId, startOfDay, endOfDay);
  
  // We only count revenue for COMPLETED orders, but might want to export all
  final completedOrders = allOrders.where((o) => o.status == 'COMPLETED').toList();

  double totalRevenue = 0;
  final Map<String, TopItem> itemAggregation = {};

  for (final order in completedOrders) {
    totalRevenue += order.total;
    
    // Fetch items for this order to calculate top items
    final items = await orderRepo.getOrderItems(order.id);
    for (final item in items) {
      if (itemAggregation.containsKey(item.itemNameSnapshot)) {
        final existing = itemAggregation[item.itemNameSnapshot]!;
        itemAggregation[item.itemNameSnapshot] = TopItem(
          name: item.itemNameSnapshot,
          quantity: existing.quantity + item.quantity,
          revenue: existing.revenue + item.total,
        );
      } else {
        itemAggregation[item.itemNameSnapshot] = TopItem(
          name: item.itemNameSnapshot,
          quantity: item.quantity,
          revenue: item.total,
        );
      }
    }
  }

  final topItemsList = itemAggregation.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity)); // Sort by quantity descending

  return DailyReport(
    totalRevenue: totalRevenue,
    totalOrders: completedOrders.length,
    topItems: topItemsList,
    rawOrders: allOrders,
  );
});
