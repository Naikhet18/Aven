import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/shared/widgets/pressable_scale.dart';

final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId == null) return [];
  return repo.getOrders(businessId);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      backgroundColor: const Color(0xFF040404),
      appBar: AppBar(
        title: const Text('Recent Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(ordersListProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => const Center(child: Text('Failed to load recent orders.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white24)
                      .animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 16),
                  const Text('No orders found.', style: TextStyle(color: Colors.white54, fontSize: 18))
                      .animate().fade(delay: 100.ms),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return PressableScale(
                onTap: () => context.go('/orders/${order.id}'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (order.paymentStatus == 'PAID' ? const Color(0xFF34C759) : const Color(0xFFFF9F0A)).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          order.paymentStatus == 'PAID' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          color: order.paymentStatus == 'PAID' ? const Color(0xFF34C759) : const Color(0xFFFF9F0A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${order.orderNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: -0.5),
                                ),
                                Text(
                                  Currency.format(order.total, symbol: currencySymbol),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${order.orderType} • ${order.status}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  order.createdAt != null ? DateFormat('hh:mm a').format(order.createdAt!) : '',
                                  style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: (index * 40).ms, duration: 400.ms).slideY(begin: 0.1, delay: (index * 40).ms);
            },
          );
        },
      ),
    );
  }
}
