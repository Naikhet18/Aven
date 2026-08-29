import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  String _selectedMethod = 'CASH'; // CASH, CARD, UPI
  double _tenderedAmount = 0.0;

  final List<double> _quickCashAmounts = [100, 200, 500, 1000, 2000];

  Future<void> _confirm(BuildContext context, {required bool paid}) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    final result = await cartNotifier.saveOrder(
      paymentStatus: paid ? 'PAID' : 'UNPAID',
      paymentMethod: paid ? _selectedMethod : null,
    );
    if (!context.mounted) return;

    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paid ? 'Payment Successful!' : 'Order placed — pay later at the table.')),
      );
      if (paid) {
        final (order, items) = result;
        // Best-effort: a printer hiccup shouldn't block the checkout flow.
        unawaited(ref.read(printerServiceProvider).printCustomerReceipt(order, items));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final settings = ref.watch(settingsProvider);
    final tax = cartState.taxFor(settings.taxRatePercent);
    final total = cartState.totalFor(settings.taxRatePercent);
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Checkout',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                )
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: isWide ? _buildWideLayout(context, cartState, settings, total) : _buildNarrowLayout(context, cartState, settings, total),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, CartState cartState, BusinessSettings settings, double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _OrderSummarySection(
              cartState: cartState,
              settings: settings,
              total: total,
              selectedMethod: _selectedMethod,
              tenderedAmount: _tenderedAmount,
              quickCashAmounts: _quickCashAmounts,
              onTenderedAmountChanged: (v) => setState(() => _tenderedAmount = v),
            ),
          ),
        ),
        Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        Expanded(
          flex: 4,
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _PaymentMethodSection(
                      selectedMethod: _selectedMethod,
                      onMethodSelected: (method, tenderedAmount) => setState(() {
                        _selectedMethod = method;
                        _tenderedAmount = tenderedAmount;
                      }),
                      total: total,
                    ),
                  ),
                ),
                _ConfirmFooter(cartState: cartState, onConfirm: _confirm),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, CartState cartState, BusinessSettings settings, double total) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderSummarySection(
                  cartState: cartState,
                  settings: settings,
                  total: total,
                  selectedMethod: _selectedMethod,
                  tenderedAmount: _tenderedAmount,
                  quickCashAmounts: _quickCashAmounts,
                  onTenderedAmountChanged: (v) => setState(() => _tenderedAmount = v),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                _PaymentMethodSection(
                  selectedMethod: _selectedMethod,
                  onMethodSelected: (method, tenderedAmount) => setState(() {
                    _selectedMethod = method;
                    _tenderedAmount = tenderedAmount;
                  }),
                  total: total,
                ),
              ],
            ),
          ),
        ),
        _ConfirmFooter(cartState: cartState, onConfirm: _confirm),
      ],
    );
  }
}

class _OrderSummarySection extends StatelessWidget {
  final CartState cartState;
  final BusinessSettings settings;
  final double total;
  final String selectedMethod;
  final double tenderedAmount;
  final List<double> quickCashAmounts;
  final ValueChanged<double> onTenderedAmountChanged;

  const _OrderSummarySection({
    required this.cartState,
    required this.settings,
    required this.total,
    required this.selectedMethod,
    required this.tenderedAmount,
    required this.quickCashAmounts,
    required this.onTenderedAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tax = cartState.taxFor(settings.taxRatePercent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              _SummaryRow('Subtotal', cartState.subtotal, settings.currencySymbol),
              if (cartState.discount > 0) ...[
                const SizedBox(height: 8),
                _SummaryRow('Discount', -cartState.discount, settings.currencySymbol, isError: true),
              ],
              const SizedBox(height: 8),
              _SummaryRow('Tax (${settings.taxRatePercent.toStringAsFixed(0)}%)', tax, settings.currencySymbol),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider()),
              _SummaryRow('Amount Due', total, settings.currencySymbol, big: true),
            ],
          ),
        ),
        if (selectedMethod == 'CASH') ...[
          const SizedBox(height: 32),
          Text('Quick Cash', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCashPill(
                amount: total,
                label: 'Exact',
                isSelected: tenderedAmount == total,
                onTap: () => onTenderedAmountChanged(total),
              ),
              ...quickCashAmounts.map((amt) {
                if (amt < total) return const SizedBox.shrink();
                return _QuickCashPill(
                  amount: amt,
                  label: Currency.format(amt, symbol: settings.currencySymbol),
                  isSelected: tenderedAmount == amt,
                  onTap: () => onTenderedAmountChanged(amt),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _SummaryRow(
              'Change Due',
              (tenderedAmount - total).clamp(0, double.infinity).toDouble(),
              settings.currencySymbol,
              big: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  final String selectedMethod;
  final void Function(String method, double tenderedAmount) onMethodSelected;
  final double total;

  const _PaymentMethodSection({required this.selectedMethod, required this.onMethodSelected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _MethodCard(
          icon: Icons.money,
          title: 'Cash',
          isSelected: selectedMethod == 'CASH',
          onTap: () => onMethodSelected('CASH', total),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          icon: Icons.credit_card,
          title: 'Credit / Debit Card',
          isSelected: selectedMethod == 'CARD',
          onTap: () => onMethodSelected('CARD', 0),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          icon: Icons.qr_code_scanner,
          title: 'UPI / QR Code',
          isSelected: selectedMethod == 'UPI',
          onTap: () => onMethodSelected('UPI', 0),
        ),
      ],
    );
  }
}

class _ConfirmFooter extends StatelessWidget {
  final CartState cartState;
  final Future<void> Function(BuildContext context, {required bool paid}) onConfirm;

  const _ConfirmFooter({required this.cartState, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          FilledButton(
            onPressed: cartState.isSaving ? null : () => onConfirm(context, paid: true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: cartState.isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (cartState.orderType == 'DINE_IN' && (cartState.tableNumber?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: cartState.isSaving ? null : () => onConfirm(context, paid: false),
              child: const Text('Place order, pay later at the table'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final bool isError;
  final bool big;

  const _SummaryRow(this.label, this.amount, this.symbol, {this.isError = false, this.big = false});

  @override
  Widget build(BuildContext context) {
    final labelStyle = big
        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        : TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final valueStyle = TextStyle(
      fontSize: big ? 20 : 15,
      fontWeight: big ? FontWeight.w900 : FontWeight.bold,
      color: isError ? Theme.of(context).colorScheme.error : (big ? Theme.of(context).colorScheme.primary : null),
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(Currency.format(amount, symbol: symbol), style: valueStyle, maxLines: 1),
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickCashPill extends StatelessWidget {
  final double amount;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickCashPill({
    required this.amount,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
