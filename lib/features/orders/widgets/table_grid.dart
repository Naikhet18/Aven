import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';

/// A visual grid of dine-in tables. A table counts as occupied if it has any
/// order that's still active (being prepared) or still unpaid -- a READY,
/// already-served order that hasn't been paid yet still holds the table.
class TableGrid extends ConsumerWidget {
  final ValueChanged<String> onTableSelected;
  const TableGrid({super.key, required this.onTableSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableCount = ref.watch(settingsProvider).tableCount;
    final activeOrders = ref.watch(activeOrdersStreamProvider).valueOrNull ?? [];
    final unpaidOrders = ref.watch(unpaidOrdersStreamProvider).valueOrNull ?? [];

    final occupied = <String>{
      for (final o in activeOrders)
        if ((o.tableNumber ?? '').isNotEmpty) o.tableNumber!,
      for (final o in unpaidOrders)
        if ((o.tableNumber ?? '').isNotEmpty) o.tableNumber!,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tableCount,
      itemBuilder: (context, index) {
        final tableNumber = '${index + 1}';
        final isOccupied = occupied.contains(tableNumber);
        return _TableTile(
          tableNumber: tableNumber,
          isOccupied: isOccupied,
          onTap: () {
            HapticFeedback.selectionClick();
            onTableSelected(tableNumber);
          },
        );
      },
    );
  }
}

class _TableTile extends StatelessWidget {
  final String tableNumber;
  final bool isOccupied;
  final VoidCallback onTap;

  const _TableTile({required this.tableNumber, required this.isOccupied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isOccupied ? Colors.orange : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant_rounded, color: color, size: 28),
              const SizedBox(height: 6),
              Text(tableNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              const SizedBox(height: 2),
              Text(
                isOccupied ? 'Occupied' : 'Available',
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
