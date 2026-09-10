import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/billing/widgets/checkout_dialog.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidOrdersAsync = ref.watch(unpaidOrdersStreamProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF040404),
      appBar: AppBar(title: const Text('Billing')),
      body: unpaidOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => const Center(child: Text('Error loading billing data.\nPlease try again later.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
        data: (orders) {
          if (orders.isEmpty) {
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
                    child: const Icon(Icons.payments_outlined, size: 72, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'No unpaid orders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All bills are settled.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final timeString = order.createdAt != null ? DateFormat('hh:mm a').format(order.createdAt!) : '';
              final isPartiallyPaid = order.paymentStatus == 'PARTIALLY_PAID';

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${order.orderNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white, letterSpacing: -0.5),
                                ),
                                if (isPartiallyPaid) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('PARTIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9F0A), letterSpacing: 0.5)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              order.tableNumber != null && order.tableNumber!.isNotEmpty
                                ? '${order.orderType} • Table ${order.tableNumber} • $timeString'
                                : '${order.orderType} • $timeString',
                              style: const TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Currency.format(order.total, symbol: currencySymbol),
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.w900, 
                              color: AppTheme.primaryColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: FilledButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => CheckoutDialog(order: order),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF34C759),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
