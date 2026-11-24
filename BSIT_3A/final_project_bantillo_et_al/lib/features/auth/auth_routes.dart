// Routes owned by the auth feature: Splash, Login, Register.
// All are full screen (outside the tab shells). Combined in app_router.dart.
//
// OWNER: team lead.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/auth/screens/login_screen.dart';
import 'package:orange150_rental/features/auth/screens/register_screen.dart';
import 'package:orange150_rental/features/auth/screens/splash_screen.dart';

/// Auth routes. Query params: `from` (return path), `staff=1` (staff login),
/// `reason` (why sign-in is needed, e.g. favorites).
final List<RouteBase> authRoutes = [
  GoRoute(
    path: RoutePaths.splash,
    name: RouteNames.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: RoutePaths.login,
    name: RouteNames.login,
    builder: (context, state) => LoginScreen(
      from: state.uri.queryParameters['from'],
      staffMode: state.uri.queryParameters['staff'] == '1',
      // Customer redesign 2: why sign-in is needed (LoginReasons).
      reason: state.uri.queryParameters[LoginReasons.param],
    ),
  ),
  GoRoute(
    path: RoutePaths.register,
    name: RouteNames.register,
    builder: (context, state) =>
        RegisterScreen(from: state.uri.queryParameters['from']),
  ),
];
