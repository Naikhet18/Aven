import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

enum ReportRange { today, week, month, custom }

final reportRangeProvider = StateProvider<ReportRange>((ref) => ReportRange.today);
final customDateRangeProvider = StateProvider<ReportDateRange?>((ref) => null);

class ReportDateRange {
  final DateTime start;
  final DateTime end;
  const ReportDateRange({required this.start, required this.end});
}

class DailyRevenue {
  final DateTime day;
  final double revenue;
  const DailyRevenue({required this.day, required this.revenue});
}

class DailyReport {
  final double totalRevenue;
  final int totalOrders;
  final double totalExpenses;
  final List<TopItem> topItems;
  final List<Order> rawOrders;
  final List<DailyRevenue> revenueByDay;
  final Map<String, double> revenueByPaymentMethod;

  DailyReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalExpenses,
    required this.topItems,
    required this.rawOrders,
    required this.revenueByDay,
    required this.revenueByPaymentMethod,
  });

  double get netProfit => totalRevenue - totalExpenses;
}

class TopItem {
  final String name;
  final double quantity;
  final double revenue;

  TopItem({required this.name, required this.quantity, required this.revenue});
}

({DateTime start, DateTime end}) _rangeFor(ReportRange range, ReportDateRange? custom) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (range) {
    case ReportRange.today:
      return (start: startOfToday, end: endOfToday);
    case ReportRange.week:
      return (start: startOfToday.subtract(const Duration(days: 6)), end: endOfToday);
    case ReportRange.month:
      return (start: startOfToday.subtract(const Duration(days: 29)), end: endOfToday);
    case ReportRange.custom:
      if (custom == null) return (start: startOfToday, end: endOfToday);
      return (start: custom.start, end: DateTime(custom.end.year, custom.end.month, custom.end.day, 23, 59, 59, 999));
  }
}

final dailyReportProvider = FutureProvider<DailyReport>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  final range = ref.watch(reportRangeProvider);
  final custom = ref.watch(customDateRangeProvider);

  if (businessId == null) {
    return DailyReport(
      totalRevenue: 0,
      totalOrders: 0,
      totalExpenses: 0,
      topItems: [],
      rawOrders: [],
      revenueByDay: [],
      revenueByPaymentMethod: {},
    );
  }

  final orderRepo = ref.watch(orderRepositoryProvider);
  final financeRepo = ref.watch(financeRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);

  final bounds = _rangeFor(range, custom);
  final allOrders = await orderRepo.getOrdersByDateRange(businessId, bounds.start, bounds.end);
  final completedOrders = allOrders.where((o) => o.status == 'COMPLETED').toList();

  double totalRevenue = 0;
  final itemAggregation = <String, TopItem>{};
  final revenueByDayMap = <String, double>{};
  final revenueByMethod = <String, double>{};
  final dayFormat = DateFormat('MMM d');

  for (final order in completedOrders) {
    totalRevenue += order.total;

    final dayKey = dayFormat.format(order.createdAt ?? bounds.start);
    revenueByDayMap.update(dayKey, (v) => v + order.total, ifAbsent: () => order.total);

    final items = await orderRepo.getOrderItems(order.id);
    for (final item in items) {
      final existing = itemAggregation[item.itemNameSnapshot];
      itemAggregation[item.itemNameSnapshot] = TopItem(
        name: item.itemNameSnapshot,
        quantity: (existing?.quantity ?? 0) + item.quantity,
        revenue: (existing?.revenue ?? 0) + item.total,
      );
    }

    final payments = await paymentRepo.getPaymentsForOrder(order.id);
    for (final payment in payments) {
      revenueByMethod.update(payment.paymentMethod, (v) => v + payment.amount, ifAbsent: () => payment.amount);
    }
  }

  final topItemsList = itemAggregation.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));

  final revenueByDay = <DailyRevenue>[];
  for (int i = 0; i <= bounds.end.difference(bounds.start).inDays; i++) {
    final day = bounds.start.add(Duration(days: i));
    revenueByDay.add(DailyRevenue(day: day, revenue: revenueByDayMap[dayFormat.format(day)] ?? 0));
  }

  final totalExpenses = await financeRepo.getTotalExpenses(businessId, bounds.start, bounds.end);

  return DailyReport(
    totalRevenue: totalRevenue,
    totalOrders: completedOrders.length,
    totalExpenses: totalExpenses,
    topItems: topItemsList,
    rawOrders: allOrders,
    revenueByDay: revenueByDay,
    revenueByPaymentMethod: revenueByMethod,
  );
});
