// Routes owned by the shop_dashboard feature. Two lists because they live
// in two different tabs of the staff shell: Dashboard and More.
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// The Settings and Staff placeholder pages are child routes of More; their
// names and paths are defined here (not in core/router/route_names.dart)
// because only this feature uses them.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_dashboard_screen.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_more_screen.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_placeholder_screen.dart';

/// Route names and paths private to the More tab.
abstract final class ShopMoreRoutes {
  /// Name of the Shop settings placeholder.
  static const String settingsName = 'shopSettings';

  /// Name of the Staff accounts placeholder.
  static const String staffName = 'shopStaff';

  /// Child path: /shop/more/settings
  static const String settingsPath = 'settings';

  /// Child path: /shop/more/staff
  static const String staffPath = 'staff';
}

/// /shop/dashboard (Dashboard tab)
final List<RouteBase> shopDashboardRoutes = [
  GoRoute(
    path: RoutePaths.shopDashboard,
    name: RouteNames.shopDashboard,
    builder: (context, state) => const ShopDashboardScreen(),
  ),
];

/// /shop/more, /shop/more/settings, /shop/more/staff (More tab)
final List<RouteBase> shopMoreRoutes = [
  GoRoute(
    path: RoutePaths.shopMore,
    name: RouteNames.shopMore,
    builder: (context, state) => const ShopMoreScreen(),
    routes: [
      GoRoute(
        path: ShopMoreRoutes.settingsPath,
        name: ShopMoreRoutes.settingsName,
        builder: (context, state) => const ShopPlaceholderScreen(
          title: 'Shop settings',
          icon: Icons.settings_outlined,
          message:
              'Shop settings are coming soon: shop hours, rental terms '
              'and how long unpaid requests stay open.',
        ),
      ),
      GoRoute(
        path: ShopMoreRoutes.staffPath,
        name: ShopMoreRoutes.staffName,
        builder: (context, state) => const ShopPlaceholderScreen(
          title: 'Staff accounts',
          icon: Icons.badge_outlined,
          message:
              'Staff accounts are coming soon. For now, promote a staff '
              'member in the Supabase SQL editor (see supabase/seed.sql).',
        ),
      ),
    ],
  ),
];
