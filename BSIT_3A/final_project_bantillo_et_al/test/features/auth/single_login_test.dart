// Single login (customers and staff use the same Login screen), no
// Supabase:
//   * where a user goes after signing in (AuthGuard.afterSignIn):
//     staff / owner -> Dashboard, ignoring `from` and pending favorites;
//     customer -> `from` (with its pending favorite) or Browse
//   * the wording: "Sign in" and "Customers and shop staff sign in here."
//   * role could not be loaded: "We couldn't load your account..." with a
//     Retry; Retry moves on by role, or stays if it fails again
// Run with: flutter test test/features/auth

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/auth/screens/login_screen.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

const _staff = AppUser(id: 's1', role: UserRole.staff);
const _owner = AppUser(id: 'o1', role: UserRole.owner);
const _customer = AppUser(id: 'c1', role: UserRole.customer);

Future<GoRouter> _pump(
  WidgetTester tester, {
  String location = RoutePaths.login,
  bool roleError = false,
  Future<AppUser?> Function()? roleLoader,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (_, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
          initialRoleError: roleError,
          roleLoader: roleLoader,
        ),
      ),
      // Any other page: show its location so the test can read it.
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, state) => Scaffold(body: Text('At ${state.uri}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('afterSignIn', () {
    test('staff and owner always go to the Dashboard', () {
      for (final user in [_staff, _owner]) {
        expect(AuthGuard.afterSignIn(user, null), RoutePaths.staffHome);
        // A customer action (Reserve, pending favorite) is ignored...
        expect(
          AuthGuard.afterSignIn(user, '/reserve/i1'),
          RoutePaths.staffHome,
        );
        expect(
          AuthGuard.afterSignIn(user, '/item/i1?fav=i1'),
          RoutePaths.staffHome,
        );
        // ...and so is a staff link: single login lands on the Dashboard.
        expect(
          AuthGuard.afterSignIn(user, '/shop/bookings'),
          RoutePaths.staffHome,
        );
      }
    });

    test('customers return to `from` (keeping a pending favorite)', () {
      expect(AuthGuard.afterSignIn(_customer, '/reserve/i1'), '/reserve/i1');
      expect(
        AuthGuard.afterSignIn(_customer, '/item/i1?fav=i1'),
        '/item/i1?fav=i1',
      );
      expect(AuthGuard.afterSignIn(_customer, null), RoutePaths.browse);
      // Never to staff pages.
      expect(
        AuthGuard.afterSignIn(_customer, '/shop/dashboard'),
        RoutePaths.browse,
      );
    });
  });

  testWidgets('one Login for everyone: title and subtitle', (tester) async {
    await _pump(tester);
    // App bar title and the button.
    expect(find.text('Sign in'), findsNWidgets(2));
    expect(find.text('Customers and shop staff sign in here.'), findsOneWidget);
    expect(find.text('Staff sign in'), findsNothing);
    expect(find.text(LoginScreen.roleErrorMessage), findsNothing);
    expect(find.text('No account yet? Create one'), findsOneWidget);
  });

  testWidgets('role not loaded: message + Retry, then the Dashboard', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '${RoutePaths.login}?from=%2Freserve%2Fi1',
      roleError: true,
      roleLoader: () async => _staff,
    );
    expect(find.text(LoginScreen.roleErrorMessage), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    // Staff: `from` (a customer action) is ignored.
    expect(find.text('At ${RoutePaths.staffHome}'), findsOneWidget);
  });

  testWidgets('Retry as a customer returns to `from`', (tester) async {
    await _pump(
      tester,
      location: '${RoutePaths.login}?from=%2Freserve%2Fi1',
      roleError: true,
      roleLoader: () async => _customer,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('At /reserve/i1'), findsOneWidget);
  });

  testWidgets('Retry that fails again stays on Login (not a customer)', (
    tester,
  ) async {
    await _pump(tester, roleError: true, roleLoader: () async => null);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(LoginScreen.roleErrorMessage), findsOneWidget);
    expect(find.textContaining('At '), findsNothing);
  });
}
