import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/reports/providers/reports_provider.dart';
import 'package:khao_piyo_pos/core/export/export_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dailyReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
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
      body: reportAsync.when(
        data: (report) => _buildReportContent(context, ref, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, WidgetRef ref, DailyReport report) {
    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(dailyReportProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Revenue',
                  value: '₹${report.totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.currency_rupee,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Orders',
                  value: '${report.totalOrders}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Top Selling Items (Today)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (report.topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No sales yet today', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.topItems.length,
              itemBuilder: (context, index) {
                final item = report.topItems[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Revenue: ₹${item.revenue.toStringAsFixed(2)}'),
                    trailing: Text('${item.quantity.toInt()} sold', style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
