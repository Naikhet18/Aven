import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/features/orders/presentation/qr_scan_screen.dart';
import 'package:khao_piyo_pos/features/reports/providers/reports_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/widgets/pressable_scale.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reportAsync = ref.watch(dailyReportProvider);
    final activeOrdersAsync = ref.watch(activeOrdersStreamProvider);
    final unpaidOrdersAsync = ref.watch(unpaidOrdersStreamProvider);
    final lowStockAsync = ref.watch(lowStockIngredientsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyReportProvider);
            ref.invalidate(lowStockIngredientsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, ${settings.name}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Here is what's happening at your business today.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2,
                      children: [
                        _MetricCard(
                          title: "Today's Sales",
                          value: reportAsync.when(
                            data: (r) => Currency.format(r.totalRevenue, symbol: settings.currencySymbol),
                            loading: () => '…',
                            error: (_, _) => '—',
                          ),
                          trend: reportAsync.when(
                            data: (r) => '${r.totalOrders} completed orders today',
                            loading: () => '',
                            error: (_, _) => 'Could not load',
                          ),
                          icon: Icons.trending_up,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _MetricCard(
                          title: 'Active Orders',
                          value: activeOrdersAsync.when(
                            data: (orders) => '${orders.length}',
                            loading: () => '…',
                            error: (_, _) => '—',
                          ),
                          trend: 'Being prepared right now',
                          icon: Icons.receipt_long,
                          color: AppTheme.warning,
                          onTap: () => context.go('/kitchen'),
                        ),
                        _MetricCard(
                          title: 'Low Stock Items',
                          value: lowStockAsync.when(
                            data: (items) => '${items.length}',
                            loading: () => '…',
                            error: (_, _) => '—',
                          ),
                          trend: lowStockAsync.when(
                            data: (items) => items.isEmpty ? 'All stocked up' : items.take(3).map((i) => i.name).join(', '),
                            loading: () => '',
                            error: (_, _) => 'Could not load',
                          ),
                          icon: Icons.inventory_2,
                          color: AppTheme.error,
                          onTap: () => context.go('/inventory'),
                        ),
                        _MetricCard(
                          title: 'Unpaid Orders',
                          value: unpaidOrdersAsync.when(
                            data: (orders) => '${orders.length}',
                            loading: () => '…',
                            error: (_, _) => '—',
                          ),
                          trend: 'Awaiting payment',
                          icon: Icons.payments_outlined,
                          color: Colors.blueAccent,
                          onTap: () => context.go('/billing'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 48),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _QuickActionButton(
                      label: 'New POS Order',
                      icon: Icons.point_of_sale,
                      onTap: () => context.go('/new-order'),
                      isPrimary: true,
                    ),
                    _QuickActionButton(
                      label: 'Kitchen Display',
                      icon: Icons.kitchen,
                      onTap: () => context.go('/kitchen'),
                    ),
                    _QuickActionButton(
                      label: 'Scan Table QR',
                      icon: Icons.qr_code_scanner,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QrScanScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scaleDown: 0.97,
      semanticLabel: onTap == null ? null : '$title, $value, $trend',
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trend,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
