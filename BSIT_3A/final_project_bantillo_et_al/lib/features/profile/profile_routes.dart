// Routes owned by the profile feature (Profile tab, customer shell).
// Combined into the customer StatefulShellRoute by core/router/app_router.dart.
// Open to guests: the screen itself shows a sign-in prompt for them.
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/profile/screens/profile_screen.dart';

/// /profile
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: RoutePaths.profile,
    name: RouteNames.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
];
