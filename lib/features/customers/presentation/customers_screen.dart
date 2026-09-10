import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/customers/providers/customers_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/widgets/glass_card.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(customersProvider)),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, _) => Center(child: Text('Failed to load customers.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54))),
        data: (customers) {
          if (customers.isEmpty) {
            final scheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: scheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No customers yet. Attach a customer at checkout to start building loyalty history.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return _CustomerTile(customer: customer, currencySymbol: currencySymbol);
            },
          );
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final String currencySymbol;
  const _CustomerTile({required this.customer, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      opacity: 0.05,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          foregroundColor: AppTheme.primaryColor,
          child: Text(
            (customer.name?.isNotEmpty ?? false) ? customer.name![0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(customer.name ?? customer.phone ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${customer.phone ?? 'No phone'} • ${customer.totalOrders} orders • ${customer.loyaltyPoints} pts\n'
          '${customer.lastVisit != null ? 'Last visit: ${DateFormat('dd MMM yyyy').format(customer.lastVisit!)}' : 'No visits yet'}',
          style: const TextStyle(color: Colors.white70),
        ),
        isThreeLine: true,
        trailing: Text(
          Currency.format(customer.totalSpent, symbol: currencySymbol),
          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
