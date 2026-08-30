import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/auth/providers/staff_role_provider.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  // Shown directly in the bottom nav bar (mobile) and always visible in the
  // rail (tablet/desktop) -- the screens a cashier touches constantly.
  // `rolesAllowed: null` means every role can see it.
  static const List<_Destination> _primaryDestinations = [
    _Destination('Dashboard', '/', Icons.dashboard_outlined, Icons.dashboard, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('New Order', '/new-order', Icons.point_of_sale_outlined, Icons.point_of_sale),
    _Destination('Kitchen', '/kitchen', Icons.kitchen_outlined, Icons.kitchen),
    _Destination('Billing', '/billing', Icons.payments_outlined, Icons.payments, rolesAllowed: {'OWNER', 'MANAGER'}),
  ];

  // Shown in the rail alongside the primary destinations on wide screens;
  // tucked behind a "More" sheet on mobile so the bottom bar doesn't end up
  // with ten items.
  static const List<_Destination> _secondaryDestinations = [
    _Destination('Orders', '/orders', Icons.receipt_long_outlined, Icons.receipt_long, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('Menu', '/menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('Inventory', '/inventory', Icons.inventory_2_outlined, Icons.inventory_2, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('Customers', '/customers', Icons.people_outline, Icons.people, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('Finance', '/finance', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, rolesAllowed: {'OWNER'}),
    _Destination('Reports', '/reports', Icons.bar_chart_outlined, Icons.bar_chart, rolesAllowed: {'OWNER', 'MANAGER'}),
    _Destination('Settings', '/settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (!authState) {
      return child;
    }

    final role = ref.watch(currentStaffRoleProvider);
    final primary = _primaryDestinations.where((d) => d.allowsRole(role)).toList();
    final secondary = _secondaryDestinations.where((d) => d.allowsRole(role)).toList();
    final location = GoRouterState.of(context).matchedLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          final all = [...primary, ...secondary];
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
                Expanded(child: _AnimatedTab(location: location, child: child)),
              ],
            ),
          );
        }

        final primaryIndex = _matchIndex(primary, location);
        final isOnSecondary = primaryIndex < 0;
        return Scaffold(
          body: _AnimatedTab(location: location, child: child),
          bottomNavigationBar: NavigationBar(
            selectedIndex: isOnSecondary ? primary.length : primaryIndex,
            onDestinationSelected: (index) {
              if (index == primary.length) {
                _showMoreSheet(context, location, secondary);
              } else {
                context.go(primary[index].path);
              }
            },
            destinations: [
              ...primary.map((d) => NavigationDestination(
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

  void _showMoreSheet(BuildContext context, String location, List<_Destination> secondary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: secondary.map((d) {
              final selected = _matchIndex(secondary, location) == secondary.indexOf(d);
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

/// Cross-fades between bottom-nav/rail destinations instead of an abrupt
/// swap. Keyed by the top-level segment of [location] (not the full path)
/// so navigating within a tab -- e.g. Orders -> an order's details -- keeps
/// its own transition rather than re-triggering this one.
class _AnimatedTab extends StatelessWidget {
  final String location;
  final Widget child;
  const _AnimatedTab({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final segment = location.split('/').skip(1).firstOrNull ?? '';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(segment), child: child),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _Destination {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// Roles allowed to see this destination. Null means every role can.
  final Set<String>? rolesAllowed;

  const _Destination(this.label, this.path, this.icon, this.selectedIcon, {this.rolesAllowed});

  // A null role means a business_id was stored before roles existed --
  // treat it as full access (see the matching note on isRouteAllowedForRole
  // in staff_role_provider.dart) rather than hiding destinations from a
  // real, already-working owner.
  bool allowsRole(String? role) => role == null || rolesAllowed == null || rolesAllowed!.contains(role);
}
