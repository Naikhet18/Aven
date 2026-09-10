import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersWithItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040404),
      appBar: AppBar(
        title: const Text('Kitchen'),
      ),
      body: activeOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => const Center(child: Text('Failed to load active tickets.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
        data: (ordersWithItems) {
          if (ordersWithItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1C1C1E),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ]
                    ),
                    child: const Icon(Icons.soup_kitchen_outlined, size: 72, color: AppTheme.primaryColor),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 2.seconds),
                  const SizedBox(height: 32),
                  const Text(
                    'No active orders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  const Text(
                    'Kitchen is clear. Waiting for tickets...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 440,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: ordersWithItems.length,
            itemBuilder: (context, index) {
              final orderData = ordersWithItems[index];
              return _OrderTicket(orderData: orderData)
                  .animate(key: ValueKey('anim_${orderData.order.id}'))
                  .fade(delay: (index * 50).ms, duration: 300.ms)
                  .slideY(begin: 0.1, delay: (index * 50).ms);
            },
          );
        },
      ),
    );
  }
}

class _OrderTicket extends ConsumerStatefulWidget {
  final OrderWithItems orderData;

  const _OrderTicket({required this.orderData});

  @override
  ConsumerState<_OrderTicket> createState() => _OrderTicketState();
}

class _OrderTicketState extends ConsumerState<_OrderTicket> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData.order;
    final items = widget.orderData.items;

    final isNew = order.status == 'NEW';
    final headerColor = isNew ? AppTheme.primaryColor : const Color(0xFFFF9F0A); // Red or Orange

    final timeElapsed = order.createdAt != null ? DateTime.now().difference(order.createdAt!).inMinutes : 0;
    final isLate = timeElapsed > 15;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  headerColor.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order.orderNumber}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(
                        order.tableNumber != null && order.tableNumber!.isNotEmpty
                            ? '${order.orderType} • Table ${order.tableNumber}'
                            : order.orderType,
                        style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLate ? const Color(0xFFF91133) : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('$timeElapsed min', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                    ],
                  ),
                ).animate(target: isLate ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white54),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.quantity.toInt()}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: headerColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemNameSnapshot, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item.notes!,
                                  style: const TextStyle(color: Color(0xFFFF9F0A), fontStyle: FontStyle.italic, fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isProcessing ? null : () async {
                  HapticFeedback.mediumImpact();
                  if (mounted) setState(() => _isProcessing = true);
                  try {
                    final repo = ref.read(orderRepositoryProvider);
                    final nextStatus = isNew ? 'PREPARING' : 'READY';
                    await repo.updateOrderStatus(order.id, nextStatus);
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isNew ? AppTheme.primaryColor : const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: (isNew ? AppTheme.primaryColor : const Color(0xFF34C759)).withValues(alpha: 0.5),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isNew ? 'Start Preparing' : 'Mark Ready',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
