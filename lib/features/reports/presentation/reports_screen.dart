import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/reports/providers/reports_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/core/export/export_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dailyReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: reportAsync.value == null ? null : () async {
              final exportService = ExportService();
              await exportService.exportOrdersToCsv(reportAsync.value!.rawOrders);
            },
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _RangeSelector(),
          ),
          Expanded(
            child: reportAsync.when(
              data: (report) => _buildReportContent(context, ref, report),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, WidgetRef ref, DailyReport report) {
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dailyReportProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Revenue',
                  value: Currency.format(report.totalRevenue, symbol: currencySymbol),
                  icon: Icons.currency_exchange,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Orders',
                  value: '${report.totalOrders}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expenses',
                  value: Currency.format(report.totalExpenses, symbol: currencySymbol),
                  icon: Icons.money_off,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Net Profit',
                  value: Currency.format(report.netProfit, symbol: currencySymbol),
                  icon: Icons.savings_outlined,
                  color: report.netProfit >= 0 ? Colors.teal : Colors.red,
                ),
              ),
            ],
          ),
          if (report.revenueByDay.length > 1) ...[
            const SizedBox(height: 24),
            const Text('Revenue trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _RevenueChart(data: report.revenueByDay)),
          ],
          if (report.revenueByPaymentMethod.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('By payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...report.revenueByPaymentMethod.entries.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(e.key),
                    trailing: Text(Currency.format(e.value, symbol: currencySymbol), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
          const SizedBox(height: 24),
          const Text('Top Selling Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (report.topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No sales in this period', style: TextStyle(color: Colors.grey))),
            )
          else
            ...report.topItems.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Revenue: ${Currency.format(item.revenue, symbol: currencySymbol)}'),
                  trailing: Text('${item.quantity.toInt()} sold', style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  const _RangeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);

    return SegmentedButton<ReportRange>(
      segments: const [
        ButtonSegment(value: ReportRange.today, label: Text('Today')),
        ButtonSegment(value: ReportRange.week, label: Text('7 Days')),
        ButtonSegment(value: ReportRange.month, label: Text('30 Days')),
        ButtonSegment(value: ReportRange.custom, label: Text('Custom')),
      ],
      selected: {range},
      onSelectionChanged: (set) async {
        final selected = set.first;
        if (selected == ReportRange.custom) {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 2),
            lastDate: now,
            initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
          );
          if (picked != null) {
            ref.read(customDateRangeProvider.notifier).state = ReportDateRange(start: picked.start, end: picked.end);
          } else {
            return;
          }
        }
        ref.read(reportRangeProvider.notifier).state = selected;
      },
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<DailyRevenue> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    final dayLabelFormat = DateFormat('d MMM');
    final labelInterval = (data.length / 6).ceilToDouble();
    final safeLabelInterval = labelInterval < 1 ? 1.0 : labelInterval;

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: safeLabelInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(dayLabelFormat.format(data[index].day), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.revenue,
                color: Theme.of(context).colorScheme.primary,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
