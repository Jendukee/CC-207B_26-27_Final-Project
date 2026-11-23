// Routes owned by the reports feature. Lives in the More tab branch of the
// staff shell (opened from the More screen).
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reports/screens/reports_screen.dart';

/// /shop/reports
final List<RouteBase> reportsRoutes = [
  GoRoute(
    path: RoutePaths.reports,
    name: RouteNames.reports,
    builder: (context, state) => const ReportsScreen(),
  ),
];
