import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return AlertDialog(
      title: Text('Checkout Order #${widget.order.orderNumber}'),
      content: SizedBox(
        width: 380,
        child: paymentsAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Error: $err'),
          data: (payments) {
            final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
            final remaining = (widget.order.total - totalPaid).clamp(0, widget.order.total);
            if (_amountController.text.isEmpty) {
              _amountController.text = remaining.toStringAsFixed(2);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total'),
                    Text(Currency.format(widget.order.total, symbol: settings.currencySymbol)),
                  ],
                ),
                if (payments.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Already paid'),
                      Text('-${Currency.format(totalPaid, symbol: settings.currencySymbol)}'),
                    ],
                  ),
                  ...payments.map((p) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text(
                          '${p.paymentMethod}: ${Currency.format(p.amount, symbol: settings.currencySymbol)}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance due', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      Currency.format(remaining.toDouble(), symbol: settings.currencySymbol),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount to collect now', border: OutlineInputBorder()),
                  enabled: !_isProcessing,
                ),
                const SizedBox(height: 16),
                const Text('Payment method:'),
                const SizedBox(height: 8),
                ..._methodButtons(remaining.toDouble()),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

  List<Widget> _methodButtons(double remaining) {
    const methods = [
      (label: 'CASH', icon: Icons.money),
      (label: 'UPI', icon: Icons.qr_code),
      (label: 'CARD', icon: Icons.credit_card),
    ];
    return methods
        .map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: _isProcessing || remaining <= 0 ? null : () => _pay(remaining, m.label),
                icon: Icon(m.icon),
                label: Text(m.label),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ))
        .toList();
  }
}
