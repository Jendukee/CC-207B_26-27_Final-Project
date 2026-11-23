// Global go_router redirect: decides who may open which route.
//
// Rules:
// 1. Until the saved session is loaded, everything waits on Splash.
// 2. Splash -> `from` (if any) or the role's home:
//      guest / customer -> Browse, staff / owner -> Dashboard.
// 3. Guests opening a sign-in route (reserve, my bookings, confirmation,
//    any /shop route) go to Login?from=<where they were going>, and are
//    returned there after signing in.
// 4. Customers cannot open /shop routes; they are sent to Browse.
// 5. Signed-in users who open Login/Register are sent on to `from`/home.
// Browse, item details, Assistant and the Profile tab stay open to guests
// (the Profile tab shows a sign-in prompt for guests).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// Redirect logic plugged into GoRouter.redirect.
abstract final class AuthGuard {
  /// Landing route for a user (or guest when [user] is null).
  static String homeFor(AppUser? user) => (user?.role.isStaff ?? false)
      ? RoutePaths.staffHome
      : RoutePaths.customerHome;

  /// Returns [from] only if it is an in-app path (prevents open redirects).
  static String? safeFrom(String? from) {
    if (from == null || from.isEmpty) return null;
    if (!from.startsWith('/') || from.startsWith('//')) return null;
    if (from.startsWith(RoutePaths.login) ||
        from.startsWith(RoutePaths.register) ||
        from.startsWith(RoutePaths.splash)) {
      return null;
    }
    return from;
  }

  /// The GoRouter redirect callback. Returns null to allow navigation.
  static String? redirect(BuildContext context, GoRouterState state) {
    final session = SessionController.instance;
    final path = state.matchedLocation;
    final here = state.uri.toString();
    final from = safeFrom(state.uri.queryParameters['from']);

    // 1. Wait for the saved session before deciding anything.
    if (!session.isReady) {
      if (path == RoutePaths.splash) return null;
      return _withFrom(RoutePaths.splash, here);
    }

    // 2. Splash forwards to the right place once ready.
    if (path == RoutePaths.splash) return from ?? homeFor(session.user);

    // 5. Already signed in: skip Login/Register.
    final isAuthPage =
        path == RoutePaths.login || path == RoutePaths.register;
    if (isAuthPage) {
      return session.isSignedIn ? (from ?? homeFor(session.user)) : null;
    }

    final needsStaff = _isUnder(path, RoutePaths.shopPrefix);
    final needsSignIn = needsStaff ||
        RoutePaths.signInRequiredPrefixes.any((p) => _isUnder(path, p));

    // 3. Guests must sign in first.
    if (needsSignIn && !session.isSignedIn) {
      return _withFrom(RoutePaths.login, here);
    }

    // 4. Customers cannot open staff routes.
    if (needsStaff && !session.isStaff) return RoutePaths.customerHome;

    return null;
  }

  /// True if [path] equals [prefix] or is nested under it.
  static bool _isUnder(String path, String prefix) =>
      path == prefix || path.startsWith('$prefix/');

  /// Builds e.g. /login?from=%2Fmy-bookings
  static String _withFrom(String target, String from) =>
      Uri(path: target, queryParameters: {'from': from}).toString();
}
