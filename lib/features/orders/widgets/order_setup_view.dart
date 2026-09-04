import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khao_piyo_pos/features/orders/widgets/table_grid.dart';
import 'package:khao_piyo_pos/shared/widgets/pressable_scale.dart';

/// The very first thing a cashier sees when starting a new order: pick the
/// order type, and for Dine In, which table it's for. Takeaway/Counter need
/// no table and complete in a single tap.
class OrderSetupView extends StatefulWidget {
  final void Function(String orderType, String? tableNumber) onComplete;
  const OrderSetupView({super.key, required this.onComplete});

  @override
  State<OrderSetupView> createState() => _OrderSetupViewState();
}

class _OrderSetupViewState extends State<OrderSetupView> {
  bool _pickingTable = false;

  void _chooseType(String type) {
    HapticFeedback.lightImpact();
    if (type == 'DINE_IN') {
      setState(() => _pickingTable = true);
    } else {
      widget.onComplete(type, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While picking a table, the Android back button/gesture should return
    // to the order-type step, not pop this screen out of the order flow
    // entirely.
    return PopScope(
      canPop: !_pickingTable,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _pickingTable) setState(() => _pickingTable = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: _pickingTable
            ? _TablePickerStep(key: const ValueKey('table'), onBack: () => setState(() => _pickingTable = false), onTableSelected: (table) => widget.onComplete('DINE_IN', table))
            : _OrderTypeStep(key: const ValueKey('type'), onChoose: _chooseType),
      ),
    );
  }
}

class _OrderTypeStep extends StatelessWidget {
  final ValueChanged<String> onChoose;
  const _OrderTypeStep({super.key, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Order', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Where is this order for?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          _OrderTypeCard(
            icon: Icons.table_restaurant_rounded,
            title: 'Dine In',
            subtitle: 'Pick a table',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => onChoose('DINE_IN'),
          ),
          const SizedBox(height: 16),
          _OrderTypeCard(
            icon: Icons.shopping_bag_rounded,
            title: 'Takeaway',
            subtitle: 'Customer collects the order',
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => onChoose('TAKEAWAY'),
          ),
          const SizedBox(height: 16),
          _OrderTypeCard(
            icon: Icons.point_of_sale_rounded,
            title: 'Counter',
            subtitle: 'Quick walk-up sale',
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => onChoose('COUNTER'),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OrderTypeCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      scaleDown: 0.98,
      semanticLabel: '$title, $subtitle',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _TablePickerStep extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onTableSelected;
  const _TablePickerStep({super.key, required this.onBack, required this.onTableSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back), tooltip: 'Back'),
              const SizedBox(width: 4),
              Text('Select a table', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TableGrid(onTableSelected: onTableSelected),
        ],
      ),
    );
  }
}
