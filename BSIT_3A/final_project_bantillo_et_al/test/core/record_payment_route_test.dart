// Regression: opening Record payment from a full-screen checklist crashed
// with "!keyReservation.contains(key)" (duplicate page keys), because the
// payment page lived inside the staff shell. It now opens on the root
// navigator. Checks the real route plus the push sequence, no Supabase.
// Run with: flutter test test/core/record_payment_route_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/navigator_keys.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_bookings/shop_bookings_routes.dart';

void main() {
  test('Record payment opens on the root navigator', () {
    final list = shopBookingsRoutes.single as GoRoute;
    final payment = list.routes.whereType<GoRoute>().singleWhere(
      (r) => r.name == RouteNames.recordPayment,
    );
    expect(payment.parentNavigatorKey, same(rootNavigatorKey));
  });

  testWidgets('checklist -> Record payment -> back: no crash', (tester) async {
    final root = GlobalKey<NavigatorState>();
    // Same shape as the app: checklist full screen, payment inside the
    // Bookings branch but on the root navigator.
    final router = GoRouter(
      navigatorKey: root,
      initialLocation: '/shop/bookings/1',
      routes: [
        GoRoute(
          path: '/shop/checklist/release/:id',
          builder: (_, _) => const Text('checklist'),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shop/dashboard',
                  builder: (_, _) => const Text('dashboard'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shop/bookings',
                  builder: (_, _) => const Text('list'),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, _) => const Text('details'),
                      routes: [
                        GoRoute(
                          path: 'payment',
                          parentNavigatorKey: root,
                          builder: (_, _) => const Text('payment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.push('/shop/checklist/release/1');
    await tester.pumpAndSettle();
    router.push('/shop/bookings/1/payment');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('payment'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('checklist'), findsOneWidget);
  });
}
