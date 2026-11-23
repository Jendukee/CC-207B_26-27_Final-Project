// Routes owned by the shop_dashboard feature. Two lists because they live
// in two different tabs of the staff shell: Dashboard and More.
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_dashboard_screen.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_more_screen.dart';

/// /shop/dashboard (Dashboard tab)
final List<RouteBase> shopDashboardRoutes = [
  GoRoute(
    path: RoutePaths.shopDashboard,
    name: RouteNames.shopDashboard,
    builder: (context, state) => const ShopDashboardScreen(),
  ),
];

/// /shop/more (More tab)
final List<RouteBase> shopMoreRoutes = [
  GoRoute(
    path: RoutePaths.shopMore,
    name: RouteNames.shopMore,
    builder: (context, state) => const ShopMoreScreen(),
  ),
];
