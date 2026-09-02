import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/features/billing/providers/billing_provider.dart';
import 'package:khao_piyo_pos/features/kitchen/providers/kitchen_provider.dart';
import 'package:khao_piyo_pos/features/tables/providers/tables_provider.dart';
import 'package:khao_piyo_pos/features/tables/widgets/add_table_dialog.dart';

/// A visual grid of dine-in tables, with an "Add Table" tile always
/// available inline -- table creation shouldn't require leaving the order
/// flow to go dig through Settings.
class TableGrid extends ConsumerWidget {
  final ValueChanged<String> onTableSelected;
  const TableGrid({super.key, required this.onTableSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);
    final activeOrders = ref.watch(activeOrdersStreamProvider).valueOrNull ?? [];
    final unpaidOrders = ref.watch(unpaidOrdersStreamProvider).valueOrNull ?? [];

    final occupied = <String>{
      for (final o in activeOrders)
        if ((o.tableNumber ?? '').isNotEmpty) o.tableNumber!,
      for (final o in unpaidOrders)
        if ((o.tableNumber ?? '').isNotEmpty) o.tableNumber!,
    };

    return tablesAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (tables) {
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
          itemCount: tables.length + 1,
          itemBuilder: (context, index) {
            if (index == tables.length) {
              return _AddTableTile(
                onAdded: () => ref.invalidate(tablesProvider),
              );
            }
            final table = tables[index];
            final isOccupied = occupied.contains(table.name);
            return _TableTile(
              tableName: table.name,
              isOccupied: isOccupied,
              onTap: () {
                HapticFeedback.selectionClick();
                onTableSelected(table.name);
              },
            );
          },
        );
      },
    );
  }
}

class _AddTableTile extends StatelessWidget {
  final VoidCallback onAdded;
  const _AddTableTile({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          HapticFeedback.lightImpact();
          await showDialog(context: context, builder: (_) => const AddTableDialog());
          onAdded();
        },
        child: DottedBorderContainer(
          color: scheme.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: scheme.primary, size: 28),
              const SizedBox(height: 6),
              Text('Add Table', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: scheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lightweight dashed-border look without a new dependency: a
/// CustomPainter drawing short dashes around a rounded rect.
class DottedBorderContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  const DottedBorderContainer({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}

class _TableTile extends StatelessWidget {
  final String tableName;
  final bool isOccupied;
  final VoidCallback onTap;

  const _TableTile({required this.tableName, required this.isOccupied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isOccupied ? AppTheme.warning : scheme.primary;

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
              Text(
                tableName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
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
