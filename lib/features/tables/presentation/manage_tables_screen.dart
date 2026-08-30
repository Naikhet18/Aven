import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/tables/providers/tables_provider.dart';
import 'package:khao_piyo_pos/features/tables/widgets/add_table_dialog.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class ManageTablesScreen extends ConsumerWidget {
  const ManageTablesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, RestaurantTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${table.name}?'),
        content: const Text('This table will no longer appear when starting a dine-in order.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tableRepositoryProvider).deleteTable(table.id);
      ref.invalidate(tablesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tables')),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No tables yet.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showDialog(context: context, builder: (_) => const AddTableDialog()),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Table'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.table_restaurant_outlined),
                  title: Text(table.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showDialog(context: context, builder: (_) => AddTableDialog(tableToEdit: table)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, table),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (_) => const AddTableDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Add Table'),
      ),
    );
  }
}
