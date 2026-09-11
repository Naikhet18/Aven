import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final Order order;

  const CheckoutDialog({super.key, required this.order});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  late final TextEditingController _amountController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay(double remaining, String method) async {
    final amount = double.tryParse(_amountController.text) ?? remaining;
    if (amount <= 0) return;

    setState(() => _isProcessing = true);
    final success = await ref.read(billingProvider.notifier).recordPayment(
          widget.order,
          amount: amount.clamp(0, remaining),
          method: method,
        );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record payment. Please try again.')),
      );
      return;
    }

    final isFullyPaid = amount.clamp(0, remaining) >= remaining - 0.01;
    if (isFullyPaid) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${widget.order.orderNumber} fully paid via $method!')),
        );
      }
      final items = await ref.read(orderRepositoryProvider).getOrderItems(widget.order.id);
      // ignore: use_build_context_synchronously
      await ref.read(printerServiceProvider).printCustomerReceipt(widget.order, items);
    } else {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${Currency.format(amount, symbol: ref.read(settingsProvider).currencySymbol)} recorded via $method. Remaining balance updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(orderPaymentsProvider(widget.order.id));
    final settings = ref.watch(settingsProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: paymentsAsync.when(
          loading: () => SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))),
          error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
          data: (payments) {
            final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
            final remaining = (widget.order.total - totalPaid).clamp(0, widget.order.total);
            if (_amountController.text.isEmpty) {
              _amountController.text = remaining.toStringAsFixed(2);
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Checkout Order #${widget.order.orderNumber}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040404),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bill', style: TextStyle(color: Colors.white54, fontSize: 16)),
                            Text(Currency.format(widget.order.total, symbol: settings.currencySymbol), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (payments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Already Paid', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              Text('-${Currency.format(totalPaid, symbol: settings.currencySymbol)}', style: const TextStyle(color: Color(0xFF34C759), fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...payments.map((p) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text('via ${p.paymentMethod}', style: const TextStyle(fontSize: 13, color: Colors.white38)),
                                  ),
                                  Text(Currency.format(p.amount, symbol: settings.currencySymbol), style: const TextStyle(fontSize: 13, color: Colors.white38)),
                                ],
                              )),
                        ],
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                            Text(
                              Currency.format(remaining.toDouble(), symbol: settings.currencySymbol),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount to collect',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixText: '${settings.currencySymbol} ',
                      prefixStyle: const TextStyle(color: Colors.white, fontSize: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryColor)),
                    ),
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: _methodButtons(remaining.toDouble()).map((b) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: b))).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _methodButtons(double remaining) {
    const methods = [
      (label: 'CASH', icon: Icons.money),
      (label: 'UPI', icon: Icons.qr_code),
      (label: 'CARD', icon: Icons.credit_card),
    ];
    return methods
        .map((m) => FilledButton(
              onPressed: _isProcessing || remaining <= 0 ? null : () => _pay(remaining, m.label),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.icon, size: 28, color: remaining <= 0 ? Colors.white38 : AppTheme.primaryColor),
                  const SizedBox(height: 8),
                  Text(m.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                ],
              ),
            ))
        .toList();
  }
}
