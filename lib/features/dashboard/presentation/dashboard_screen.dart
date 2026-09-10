import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final comparisonAsync = ref.watch(dashboardComparisonProvider);
    final activeOrdersAsync = ref.watch(activeOrdersStreamProvider);
    final unpaidOrdersAsync = ref.watch(unpaidOrdersStreamProvider);
    final lowStockAsync = ref.watch(lowStockIngredientsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040404), // True OLED black
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () async {
            ref.invalidate(dashboardComparisonProvider);
            ref.invalidate(lowStockIngredientsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Settings Name & Sync)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      settings.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        fontSize: 12,
                      ),
                    ),
                    const SyncStatusChip(),
                  ],
                ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
                
                const SizedBox(height: 32),

                // Hero Revenue Section (matching UI Inspo big text)
                comparisonAsync.when(
                  data: (c) => AnimatedCounter(
                    value: c.todayRevenue,
                    formatter: (v) => Currency.format(v, symbol: settings.currencySymbol),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56, // Even bigger
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  loading: () => Text('...', style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 56, fontWeight: FontWeight.w600))
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1200.ms, color: Colors.white38),
                  error: (_, _) => const Text('—', style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w600)),
                ).animate(delay: 100.ms).fade(duration: 500.ms).slideX(begin: -0.1),
                
                const SizedBox(height: 8),

                comparisonAsync.maybeWhen(
                  data: (c) => Row(
                    children: [
                      TrendBadge(percent: c.revenueChangePercent, onTint: true),
                      const SizedBox(width: 12),
                      Text(
                        '${c.todayOrders} orders today',
                        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ).animate(delay: 200.ms).fade(duration: 500.ms),

                const SizedBox(height: 48),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: PressableScale(
                        onTap: () => context.go('/new-order'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'New Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: PressableScale(
                        onTap: () => context.go('/orders'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'All Orders',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // More quick actions row
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () => context.go('/kitchen'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.soup_kitchen_outlined, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text('Kitchen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PressableScale(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScanScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text('Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 400.ms).fade(duration: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 48),

                // Section Title
                const _SectionHeader(title: 'Overview').animate(delay: 500.ms).fade().slideX(begin: -0.1),
                
                const SizedBox(height: 20),

                // Horizontal Scrolling Cards
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _StatCard(
                        title: 'ACTIVE\nORDERS',
                        value: activeOrdersAsync.when(
                          data: (o) => o.length.toDouble(),
                          loading: () => null,
                          error: (_, _) => -1.0,
                        ),
                        color: Colors.orangeAccent,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: 'UNPAID\nBILLS',
                        value: unpaidOrdersAsync.when(
                          data: (o) => o.length.toDouble(),
                          loading: () => null,
                          error: (_, _) => -1.0,
                        ),
                        color: Colors.blueAccent,
                        icon: Icons.receipt_long_rounded,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: 'LOW\nSTOCK',
                        value: lowStockAsync.when(
                          data: (i) => i.length.toDouble(),
                          loading: () => null,
                          error: (_, _) => -1.0,
                        ),
                        color: AppTheme.primaryColor,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ].animate(interval: 100.ms, delay: 600.ms).fade(duration: 400.ms).slideY(begin: 0.2),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double? value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return PressableScale(
      onTap: () {},
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Dark grey from UI inspo
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            v == null
                ? Text('...', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.2)))
                    .animate(onPlay: (c) => c.repeat()).shimmer()
                : v < 0
                    ? const Text('—', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white54))
                    : AnimatedCounter(
                        value: v,
                        formatter: (n) => n.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                          height: 1.0,
                        ),
                      ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
