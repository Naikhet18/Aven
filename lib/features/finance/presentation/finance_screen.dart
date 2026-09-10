import 'package:flutter/material.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/finance/providers/finance_provider.dart';
import 'package:khao_piyo_pos/features/finance/widgets/add_expense_dialog.dart';
import 'package:khao_piyo_pos/features/finance/widgets/add_supplier_dialog.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Suppliers')]),
        ),
        body: const TabBarView(children: [_ExpensesTab(), _SuppliersTab()]),
        floatingActionButton: Builder(builder: (context) {
          final isExpensesTab = DefaultTabController.of(context).index == 0;
          return FloatingActionButton.extended(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => isExpensesTab ? const AddExpenseDialog() : const AddSupplierDialog(),
            ),
            icon: const Icon(Icons.add),
            label: Text(isExpensesTab ? 'Expense' : 'Supplier'),
          );
        }),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, _) => const Center(child: Text('Failed to load expenses.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
      data: (expenses) {
        if (expenses.isEmpty) return const Center(child: Text('No expenses recorded yet.', style: TextStyle(color: Colors.white54)));
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(Currency.format(total, symbol: currencySymbol), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final e = expenses[index];
                  return ListTile(
                    title: Text(e.category),
                    subtitle: Text('${DateFormat('dd MMM yyyy').format(e.expenseDate)}${e.notes != null ? ' • ${e.notes}' : ''}'),
                    trailing: Text(Currency.format(e.amount, symbol: currencySymbol), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuppliersTab extends ConsumerWidget {
  const _SuppliersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return suppliersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, _) => const Center(child: Text('Failed to load suppliers.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
      data: (suppliers) {
        if (suppliers.isEmpty) return const Center(child: Text('No suppliers added yet.', style: TextStyle(color: Colors.white54)));
        return ListView.builder(
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            final s = suppliers[index];
            return ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(s.name),
              subtitle: Text([if (s.phone != null) s.phone!, if (s.email != null) s.email!].join(' • ')),
            );
          },
        );
      },
    );
  }
}
