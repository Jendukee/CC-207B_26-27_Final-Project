// Routes owned by the profile feature (Profile tab, customer shell).
// /profile is open to guests (it shows a sign-in prompt); the Privacy and
// data page (customer redesign) is a child: /profile/privacy.
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/profile/screens/privacy_screen.dart';
import 'package:orange150_rental/features/profile/screens/profile_screen.dart';

/// Route names and paths private to the profile feature.
abstract final class ProfileRoutes {
  /// Name of the Privacy and data page.
  static const String privacyName = 'profilePrivacy';

  /// Child path: /profile/privacy
  static const String privacyPath = 'privacy';
}

/// /profile and /profile/privacy
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: RoutePaths.profile,
    name: RouteNames.profile,
    builder: (context, state) => const ProfileScreen(),
    routes: [
      GoRoute(
        path: ProfileRoutes.privacyPath,
        name: ProfileRoutes.privacyName,
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  ),
];
