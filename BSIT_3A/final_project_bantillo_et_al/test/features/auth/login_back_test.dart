// Login's back arrow and guest link (customer redesign 2, Phase 1):
//   * opened from another screen (e.g. Reserve Now or a heart): Back goes
//     back there, and nothing is completed
//   * opened directly (no history): Back goes to Browse
//   * "Continue browsing as guest" goes to Browse
//   * the reason line, e.g. "Sign in to save favorites"
// The screen builds without Supabase (AuthService is created on first use).
// Run with: flutter test test/features/auth

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/auth/screens/login_screen.dart';

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: RoutePaths.browse,
      builder: (_, _) => const Scaffold(body: Text('Browse page')),
    ),
    GoRoute(
      path: '/item',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push(
            '${RoutePaths.login}?from=%2Freserve%2Fi1&reason=reserve',
          ),
          child: const Text('Reserve Now'),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (_, state) => LoginScreen(
        from: state.uri.queryParameters['from'],
        reason: state.uri.queryParameters[LoginReasons.param],
      ),
    ),
  ],
);

Future<GoRouter> _pump(WidgetTester tester, String initial) async {
  final router = _router(initial);
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
  testWidgets('opened from an action: Back returns there', (tester) async {
    final router = await _pump(tester, '/item');
    await tester.tap(find.text('Reserve Now'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to reserve this item'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Reserve Now'), findsOneWidget);
    // Back went to the item, not to the action's `from` (/reserve/i1).
    expect(router.routerDelegate.currentConfiguration.uri.path, '/item');
  });

  testWidgets('opened directly: Back goes to Browse', (tester) async {
    final router = await _pump(tester, RoutePaths.login);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Browse page'), findsOneWidget);
  });

  testWidgets('"Continue browsing as guest" goes to Browse', (tester) async {
    await _pump(tester, RoutePaths.login);
    await tester.ensureVisible(find.text('Continue browsing as guest'));
    await tester.tap(find.text('Continue browsing as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Browse page'), findsOneWidget);
  });

  testWidgets('a favorites reason is shown; unknown reasons are not', (
    tester,
  ) async {
    await _pump(tester, '${RoutePaths.login}?reason=favorites');
    expect(find.text('Sign in to save favorites'), findsOneWidget);
    expect(LoginScreen.reasonText('anything else'), isNull);
  });
}
