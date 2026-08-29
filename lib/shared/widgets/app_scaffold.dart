import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show navigation if authenticated
    final authState = ref.watch(authStateProvider);
    if (!authState) {
      return child;
    }

    final location = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = _calculateSelectedIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screen (tablet/desktop) -> NavigationRail
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: _navDestinations
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

        // Narrow screen (mobile) -> NavigationBar
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            destinations: _navDestinations
                .map((d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  static int _calculateSelectedIndex(String location) {
    if (location.startsWith('/menu')) return 1;
    if (location.startsWith('/orders') || location.startsWith('/new-order')) return 2;
    if (location.startsWith('/kitchen')) return 3;
    if (location.startsWith('/billing')) return 4;
    if (location.startsWith('/reports')) return 5;
    if (location.startsWith('/settings')) return 6;
    return 0; // Dashboard (or default)
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/menu');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/kitchen');
        break;
      case 4:
        context.go('/billing');
        break;
      case 5:
        context.go('/reports');
        break;
      case 6:
        context.go('/settings');
        break;
    }
  }

  static const List<_Destination> _navDestinations = [
    _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Destination('Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu),
    _Destination('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
    _Destination('Kitchen', Icons.kitchen_outlined, Icons.kitchen),
    _Destination('Billing', Icons.point_of_sale_outlined, Icons.point_of_sale),
    _Destination('Reports', Icons.bar_chart_outlined, Icons.bar_chart),
    _Destination('Settings', Icons.settings_outlined, Icons.settings),
  ];
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.label, this.icon, this.selectedIcon);
}
