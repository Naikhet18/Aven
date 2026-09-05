import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/features/dashboard/presentation/dashboard_screen.dart';
import 'package:khao_piyo_pos/features/menu/presentation/menu_screen.dart';
import 'package:khao_piyo_pos/features/orders/presentation/new_order_screen.dart';
import 'package:khao_piyo_pos/features/orders/presentation/orders_screen.dart';
import 'package:khao_piyo_pos/features/kitchen/presentation/kitchen_screen.dart';
import 'package:khao_piyo_pos/features/billing/presentation/billing_screen.dart';
import 'package:khao_piyo_pos/features/auth/presentation/login_screen.dart';
import 'package:khao_piyo_pos/features/auth/providers/staff_role_provider.dart';

import 'package:khao_piyo_pos/features/settings/presentation/settings_screen.dart';

import 'package:khao_piyo_pos/features/reports/presentation/reports_screen.dart';
import 'package:khao_piyo_pos/features/inventory/presentation/inventory_screen.dart';
import 'package:khao_piyo_pos/features/customers/presentation/customers_screen.dart';
import 'package:khao_piyo_pos/features/finance/presentation/finance_screen.dart';
import 'package:khao_piyo_pos/features/orders/presentation/order_details_screen.dart';
import 'package:khao_piyo_pos/features/splash/presentation/splash_screen.dart';
import 'package:khao_piyo_pos/features/tables/presentation/manage_tables_screen.dart';

import 'package:khao_piyo_pos/shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app's router using the [SharedPreferences] instance main()
/// already loaded before calling runApp() -- letting `redirect` read it
/// synchronously instead of calling `SharedPreferences.getInstance()` (and
/// `await`ing it) on every single navigation. An `async` redirect yields to
/// the event loop before resolving, which is unnecessary latency on every
/// navigation in the app; reading the already-loaded instance directly
/// avoids it.
GoRouter buildAppRouter(SharedPreferences prefs) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // The splash screen owns the initial routing decision (it does real
      // async init first); don't fight with it while it's still booting.
      if (state.matchedLocation == '/splash') return null;

      var businessId = prefs.getString('business_id');

      // A locally-remembered business_id doesn't mean the Supabase session is
      // still valid (e.g. the user signed out elsewhere, or the token
      // expired without a stored refresh token). Treat a missing session the
      // same as never having logged in. The actual removal is fire-and-forget
      // disk cleanup -- this redirect's decision only needs the in-memory
      // value cleared, not the write to complete.
      if (businessId != null &&
          Supabase.instance.client.auth.currentSession == null) {
        unawaited(prefs.remove('business_id'));
        businessId = null;
      }

      final isLoggingIn = state.matchedLocation == '/login';

      if (businessId == null && !isLoggingIn) {
        return '/login';
      }

      if (businessId == null) {
        return null; // on /login with no business yet: fine
      }

      final role = prefs.getString('staff_role');

      if (isLoggingIn) {
        return homeRouteForRole(role);
      }

      // Defense in depth: a route hidden from a role's nav (see AppScaffold)
      // shouldn't still be reachable via a deep link, back button, or stale
      // bookmark.
      if (!isRouteAllowedForRole(role, state.matchedLocation)) {
        return homeRouteForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/menu',
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    OrderDetailsScreen(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/new-order',
            builder: (context, state) => const NewOrderScreen(),
          ),
          GoRoute(
            path: '/kitchen',
            builder: (context, state) => const KitchenScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'tables',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ManageTablesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
