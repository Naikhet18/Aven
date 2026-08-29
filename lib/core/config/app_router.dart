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

import 'package:khao_piyo_pos/features/settings/presentation/settings_screen.dart';

import 'package:khao_piyo_pos/features/reports/presentation/reports_screen.dart';

import 'package:khao_piyo_pos/shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    var businessId = prefs.getString('business_id');

    // A locally-remembered business_id doesn't mean the Supabase session is
    // still valid (e.g. the user signed out elsewhere, or the token
    // expired without a stored refresh token). Treat a missing session the
    // same as never having logged in.
    if (businessId != null && Supabase.instance.client.auth.currentSession == null) {
      await prefs.remove('business_id');
      businessId = null;
    }

    final isLoggingIn = state.matchedLocation == '/login';

    if (businessId == null && !isLoggingIn) {
      return '/login';
    }

    if (businessId != null && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
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
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
