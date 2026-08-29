import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/customers/providers/customers_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';

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
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(customersProvider)),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(
              child: Text('No customers yet. Attach a customer at checkout to start building loyalty history.'),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text((customer.name?.isNotEmpty ?? false) ? customer.name![0].toUpperCase() : '?')),
        title: Text(customer.name ?? customer.phone ?? 'Unknown'),
        subtitle: Text(
          '${customer.phone ?? 'No phone'} • ${customer.totalOrders} orders • ${customer.loyaltyPoints} pts\n'
          '${customer.lastVisit != null ? 'Last visit: ${DateFormat('dd MMM yyyy').format(customer.lastVisit!)}' : 'No visits yet'}',
        ),
        isThreeLine: true,
        trailing: Text(
          Currency.format(customer.totalSpent, symbol: currencySymbol),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
