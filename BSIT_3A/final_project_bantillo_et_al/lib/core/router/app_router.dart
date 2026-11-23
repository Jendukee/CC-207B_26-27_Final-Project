// The single GoRouter for the app.
//
// This file ONLY combines the route lists exported by each feature's
// <feature>_routes.dart. To add or change a screen, edit your own
// feature's routes file, not this one.
//
// Layout:
// - Top-level (full screen): auth, reservation flow, checklists.
// - Customer shell (StatefulShellRoute): Browse | Assistant | My Bookings | Profile
//   (always a bottom navigation bar)
// - Staff shell (StatefulShellRoute):    Dashboard | Calendar | Bookings | Inventory | More
//   (bottom bar on phones, side rail at >= 600 px)
// Each shell keeps the state of every tab (IndexedStack).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/widgets/responsive_scaffold.dart';
import 'package:orange150_rental/features/assistant/assistant_routes.dart';
import 'package:orange150_rental/features/auth/auth_routes.dart';
import 'package:orange150_rental/features/catalog/catalog_routes.dart';
import 'package:orange150_rental/features/checklist/checklist_routes.dart';
import 'package:orange150_rental/features/inventory/inventory_routes.dart';
import 'package:orange150_rental/features/my_bookings/my_bookings_routes.dart';
import 'package:orange150_rental/features/profile/profile_routes.dart';
import 'package:orange150_rental/features/reports/reports_routes.dart';
import 'package:orange150_rental/features/reservation/reservation_routes.dart';
import 'package:orange150_rental/features/shop_bookings/shop_bookings_routes.dart';
import 'package:orange150_rental/features/shop_calendar/shop_calendar_routes.dart';
import 'package:orange150_rental/features/shop_dashboard/shop_dashboard_routes.dart';

/// Holds the app's [GoRouter].
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> _rootKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Customer tabs, in branch order.
  static const List<ResponsiveDestination> _customerTabs = [
    ResponsiveDestination(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Browse',
    ),
    ResponsiveDestination(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'Assistant',
    ),
    ResponsiveDestination(
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      label: 'My Bookings',
    ),
    ResponsiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  /// Staff tabs, in branch order.
  static const List<ResponsiveDestination> _staffTabs = [
    ResponsiveDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    ResponsiveDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Calendar',
    ),
    ResponsiveDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Bookings',
    ),
    ResponsiveDestination(
      icon: Icons.checkroom_outlined,
      selectedIcon: Icons.checkroom,
      label: 'Inventory',
    ),
    ResponsiveDestination(
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
      label: 'More',
    ),
  ];

  /// The router passed to MaterialApp.router. Re-evaluates redirects
  /// whenever [SessionController] changes (sign in, sign out, role loaded).
  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: SessionController.instance,
    redirect: AuthGuard.redirect,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => RoutePaths.splash),

      // Full-screen routes (no tab bar).
      ...authRoutes,
      ...reservationRoutes,
      ...checklistRoutes,

      // Customer shell: bottom navigation bar at every screen width.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ResponsiveScaffold(
          navigationShell: shell,
          destinations: _customerTabs,
          alwaysBottomBar: true,
        ),
        branches: [
          StatefulShellBranch(routes: catalogRoutes),
          StatefulShellBranch(routes: assistantRoutes),
          StatefulShellBranch(routes: myBookingsRoutes),
          StatefulShellBranch(routes: profileRoutes),
        ],
      ),

      // Staff shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ResponsiveScaffold(navigationShell: shell, destinations: _staffTabs),
        branches: [
          StatefulShellBranch(routes: shopDashboardRoutes),
          StatefulShellBranch(routes: shopCalendarRoutes),
          StatefulShellBranch(routes: shopBookingsRoutes),
          StatefulShellBranch(routes: inventoryRoutes),
          StatefulShellBranch(routes: [...shopMoreRoutes, ...reportsRoutes]),
        ],
      ),
    ],
  );
}
