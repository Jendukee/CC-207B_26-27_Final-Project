// Routes owned by the shop_calendar feature (Calendar tab, staff shell).
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_calendar/screens/shop_calendar_screen.dart';

/// /shop/calendar
final List<RouteBase> shopCalendarRoutes = [
  GoRoute(
    path: RoutePaths.shopCalendar,
    name: RouteNames.shopCalendar,
    builder: (context, state) => const ShopCalendarScreen(),
  ),
];
