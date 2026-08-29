import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  // Shown directly in the bottom nav bar (mobile) and always visible in the
  // rail (tablet/desktop) -- the screens a cashier touches constantly.
  static const List<_Destination> _primaryDestinations = [
    _Destination('Dashboard', '/', Icons.dashboard_outlined, Icons.dashboard),
    _Destination('New Order', '/new-order', Icons.point_of_sale_outlined, Icons.point_of_sale),
    _Destination('Kitchen', '/kitchen', Icons.kitchen_outlined, Icons.kitchen),
    _Destination('Billing', '/billing', Icons.payments_outlined, Icons.payments),
  ];

  // Shown in the rail alongside the primary destinations on wide screens;
  // tucked behind a "More" sheet on mobile so the bottom bar doesn't end up
  // with ten items.
  static const List<_Destination> _secondaryDestinations = [
    _Destination('Orders', '/orders', Icons.receipt_long_outlined, Icons.receipt_long),
    _Destination('Menu', '/menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu),
    _Destination('Inventory', '/inventory', Icons.inventory_2_outlined, Icons.inventory_2),
    _Destination('Customers', '/customers', Icons.people_outline, Icons.people),
    _Destination('Finance', '/finance', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
    _Destination('Reports', '/reports', Icons.bar_chart_outlined, Icons.bar_chart),
    _Destination('Settings', '/settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (!authState) {
      return child;
    }

    final location = GoRouterState.of(context).matchedLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          final all = [..._primaryDestinations, ..._secondaryDestinations];
          final selectedIndex = _matchIndex(all, location);
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                  onDestinationSelected: (index) => context.go(all[index].path),
                  labelType: NavigationRailLabelType.all,
                  destinations: all
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        final primaryIndex = _matchIndex(_primaryDestinations, location);
        final isOnSecondary = primaryIndex < 0;
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: isOnSecondary ? _primaryDestinations.length : primaryIndex,
            onDestinationSelected: (index) {
              if (index == _primaryDestinations.length) {
                _showMoreSheet(context, location);
              } else {
                context.go(_primaryDestinations[index].path);
              }
            },
            destinations: [
              ..._primaryDestinations.map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  )),
              const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        );
      },
    );
  }

  static int _matchIndex(List<_Destination> destinations, String location) {
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (path == '/' ? location == '/' : location.startsWith(path)) return i;
    }
    return -1;
  }

  void _showMoreSheet(BuildContext context, String location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _secondaryDestinations.map((d) {
              final selected = _matchIndex(_secondaryDestinations, location) == _secondaryDestinations.indexOf(d);
              return ListTile(
                leading: Icon(selected ? d.selectedIcon : d.icon),
                title: Text(d.label),
                selected: selected,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(d.path);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _Destination {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.label, this.path, this.icon, this.selectedIcon);
}
