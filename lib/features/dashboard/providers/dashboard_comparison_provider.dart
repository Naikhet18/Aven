import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

/// Real revenue/order-count deltas of today vs. the same point yesterday --
/// not a decorative number. Null percent means there's nothing meaningful
/// to compare against (yesterday had zero), handled explicitly by
/// TrendBadge rather than showing a misleading 0%/∞%.
class DashboardComparison {
  final double todayRevenue;
  final int todayOrders;
  final double? revenueChangePercent;
  final double? ordersChangePercent;

  const DashboardComparison({
    required this.todayRevenue,
    required this.todayOrders,
    required this.revenueChangePercent,
    required this.ordersChangePercent,
  });
}

double? _percentChange(num today, num yesterday) {
  if (yesterday == 0) return null;
  return ((today - yesterday) / yesterday) * 100;
}

final dashboardComparisonProvider = FutureProvider<DashboardComparison>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) {
    return const DashboardComparison(todayRevenue: 0, todayOrders: 0, revenueChangePercent: null, ordersChangePercent: null);
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

  // Compare like-for-like: yesterday up to the same minute today has
  // reached, so a 10am comparison isn't skewed by a full extra day of data.
  final sameTimeYesterday = startOfYesterday.add(now.difference(startOfToday));

  final todayOrders = await orderRepo.getOrdersByDateRange(businessId, startOfToday, now);
  final yesterdayOrders = await orderRepo.getOrdersByDateRange(businessId, startOfYesterday, sameTimeYesterday);

  final todayCompleted = todayOrders.where((o) => o.status == 'COMPLETED').toList();
  final yesterdayCompleted = yesterdayOrders.where((o) => o.status == 'COMPLETED').toList();

  final todayRevenue = todayCompleted.fold<double>(0, (sum, o) => sum + o.total);
  final yesterdayRevenue = yesterdayCompleted.fold<double>(0, (sum, o) => sum + o.total);

  return DashboardComparison(
    todayRevenue: todayRevenue,
    todayOrders: todayCompleted.length,
    revenueChangePercent: _percentChange(todayRevenue, yesterdayRevenue),
    ordersChangePercent: _percentChange(todayCompleted.length, yesterdayCompleted.length),
  );
});
