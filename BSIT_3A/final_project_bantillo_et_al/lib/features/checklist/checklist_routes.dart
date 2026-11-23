// Routes owned by the checklist feature. Full screen (outside the staff
// shell) so staff can focus on the release/return checklist.
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/checklist/screens/release_checklist_screen.dart';
import 'package:orange150_rental/features/checklist/screens/return_checklist_screen.dart';

/// /shop/checklist/release/:bookingId and /shop/checklist/return/:bookingId
final List<RouteBase> checklistRoutes = [
  GoRoute(
    path: RoutePaths.releaseChecklist,
    name: RouteNames.releaseChecklist,
    builder: (context, state) =>
        ReleaseChecklistScreen(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
    path: RoutePaths.returnChecklist,
    name: RouteNames.returnChecklist,
    builder: (context, state) =>
        ReturnChecklistScreen(bookingId: state.pathParameters['bookingId']!),
  ),
];
