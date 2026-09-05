import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/dashboard/providers/dashboard_comparison_provider.dart';
import 'package:khao_piyo_pos/features/inventory/providers/inventory_provider.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/features/orders/presentation/qr_scan_screen.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/widgets/animated_counter.dart';
import 'package:khao_piyo_pos/shared/widgets/pressable_scale.dart';
import 'package:khao_piyo_pos/shared/widgets/sync_status_chip.dart';
import 'package:khao_piyo_pos/shared/widgets/trend_badge.dart';

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
    final comparisonAsync = ref.watch(dashboardComparisonProvider);
    final activeOrdersAsync = ref.watch(activeOrdersStreamProvider);
    final unpaidOrdersAsync = ref.watch(unpaidOrdersStreamProvider);
    final lowStockAsync = ref.watch(lowStockIngredientsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardComparisonProvider);
            ref.invalidate(lowStockIngredientsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _greeting(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SyncStatusChip(),
                  ],
                ),
                const SizedBox(height: 4),
                // The business name has no length limit the app controls --
                // cap it to two lines so a long name can never balloon the
                // header into most of the screen the way an uncapped
                // display-size headline did.
                Text(
                  settings.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Here is what's happening at your business today.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Hero card: the day's headline number, given real visual
                // weight (gradient, large type, live count-up) instead of
                // being just another tile in a uniform grid.
                _HeroSalesCard(
                  comparisonAsync: comparisonAsync,
                  currencySymbol: settings.currencySymbol,
                  isDark: isDark,
                ),

                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 500 ? 3 : 1;
                    // A fixed row height (not an aspect ratio) so the card's
                    // fixed-height content -- icon, count-up number, title,
                    // subtitle -- always fits regardless of column count or
                    // screen width; an aspect ratio scales height with width,
                    // which doesn't track fixed text content and overflows
                    // on narrow phones.
                    return GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: crossAxisCount == 1 ? 118 : 172,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _BentoStatCard(
                          title: 'Active Orders',
                          value: activeOrdersAsync.when(
                            data: (orders) => orders.length.toDouble(),
                            loading: () => null,
                            error: (_, _) => null,
                          ),
                          subtitle: 'Being prepared right now',
                          icon: Icons.receipt_long_rounded,
                          color: AppTheme.warning,
                          onTap: () => context.go('/kitchen'),
                          horizontal: crossAxisCount == 1,
                        ),
                        _BentoStatCard(
                          title: 'Low Stock',
                          value: lowStockAsync.when(
                            data: (items) => items.length.toDouble(),
                            loading: () => null,
                            error: (_, _) => null,
                          ),
                          subtitle: lowStockAsync.when(
                            data: (items) => items.isEmpty ? 'All stocked up' : items.take(3).map((i) => i.name).join(', '),
                            loading: () => '',
                            error: (_, _) => 'Could not load',
                          ),
                          icon: Icons.inventory_2_rounded,
                          color: AppTheme.error,
                          onTap: () => context.go('/inventory'),
                          horizontal: crossAxisCount == 1,
                        ),
                        _BentoStatCard(
                          title: 'Unpaid',
                          value: unpaidOrdersAsync.when(
                            data: (orders) => orders.length.toDouble(),
                            loading: () => null,
                            error: (_, _) => null,
                          ),
                          subtitle: 'Awaiting payment',
                          icon: Icons.payments_rounded,
                          color: scheme.tertiary,
                          onTap: () => context.go('/billing'),
                          horizontal: crossAxisCount == 1,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionButton(
                      label: 'New POS Order',
                      icon: Icons.point_of_sale_rounded,
                      onTap: () => context.go('/new-order'),
                      isPrimary: true,
                    ),
                    _QuickActionButton(
                      label: 'Kitchen Display',
                      icon: Icons.soup_kitchen_rounded,
                      onTap: () => context.go('/kitchen'),
                    ),
                    _QuickActionButton(
                      label: 'Scan Table QR',
                      icon: Icons.qr_code_scanner_rounded,
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

class _HeroSalesCard extends StatelessWidget {
  final AsyncValue<DashboardComparison> comparisonAsync;
  final String currencySymbol;
  final bool isDark;

  const _HeroSalesCard({required this.comparisonAsync, required this.currencySymbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(dark: isDark),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // A faint oversized icon as a signature decorative touch --
            // pure Flutter, zero asset weight, reads as intentional brand
            // texture rather than a placeholder.
            Positioned(
              right: -18,
              bottom: -24,
              child: Icon(Icons.storefront_rounded, size: 140, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Sales",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  comparisonAsync.when(
                    data: (c) => AnimatedCounter(
                      value: c.todayRevenue,
                      formatter: (v) => Currency.format(v, symbol: currencySymbol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1.0,
                      ),
                    ),
                    loading: () => const Text('…', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    error: (_, _) => const Text('—', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      comparisonAsync.maybeWhen(
                        data: (c) => TrendBadge(percent: c.revenueChangePercent, onTint: true),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),
                      Text('vs yesterday', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      const Spacer(),
                      comparisonAsync.maybeWhen(
                        data: (c) => Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              '${c.todayOrders} orders',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  final String title;
  final double? value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool horizontal;

  const _BentoStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value;

    final iconBadge = Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );

    final counter = v == null
        ? const Text('…', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        : AnimatedCounter(
            value: v,
            formatter: (n) => n.toInt().toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
          );

    final titleText = Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: scheme.onSurfaceVariant));
    final subtitleText = Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.75)),
    );

    final content = horizontal
        ? Row(
            children: [
              iconBadge,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [counter, const SizedBox(height: 2), titleText, const SizedBox(height: 2), subtitleText],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconBadge,
              const SizedBox(height: 12),
              counter,
              const SizedBox(height: 2),
              titleText,
              const SizedBox(height: 2),
              subtitleText,
            ],
          );

    return PressableScale(
      onTap: onTap,
      scaleDown: 0.96,
      semanticLabel: onTap == null ? null : '$title, ${v?.toInt() ?? '—'}, $subtitle',
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: content,
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
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: [AppTheme.primaryColor, Color.lerp(AppTheme.primaryColor, Colors.black, 0.25)!])
              : null,
          color: isPrimary ? null : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: isPrimary ? Colors.transparent : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : scheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
