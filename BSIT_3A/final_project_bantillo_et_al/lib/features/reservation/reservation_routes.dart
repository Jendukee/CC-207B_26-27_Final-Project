// Routes owned by the reservation feature. Full screen (outside the tab
// shell), sign-in required (auth_guard: everything under /reserve).
//
// Flow: Item details -> Reserve sheet (date) -> Checkout -> Request
// submitted. Item details opens the checkout BY PATH:
//   /reserve/:itemId/checkout?date=yyyy-MM-dd
//
// Phase 2 removed the old step screens (dates, measurements, review). The
// old /reserve/:itemId/dates path is kept as a redirect to the item page,
// so old links still work (routes are never renamed).
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reservation/screens/booking_confirmation_screen.dart';
import 'package:orange150_rental/features/reservation/screens/checkout_screen.dart';

/// Route names and paths added by the redesign (defined here, not in
/// core/router/route_names.dart, because only this feature owns them).
abstract final class ReservationRoutes {
  /// Name of the checkout route.
  static const String checkoutName = 'reserveCheckout';

  /// /reserve/:itemId/checkout?date=yyyy-MM-dd
  static const String checkoutPath = '/reserve/:itemId/checkout';
}

/// All reservation routes.
final List<RouteBase> reservationRoutes = [
  // Old link: the Reserve sheet on the item page replaces this step.
  GoRoute(
    path: RoutePaths.reserveDates,
    name: RouteNames.reserveDates,
    redirect: (context, state) =>
        '${RoutePaths.browse}/item/${state.pathParameters['itemId']}',
  ),
  GoRoute(
    path: ReservationRoutes.checkoutPath,
    name: ReservationRoutes.checkoutName,
    builder: (context, state) => CheckoutScreen(
      itemId: state.pathParameters['itemId']!,
      eventDate: parseCheckoutDate(state.uri.queryParameters['date']),
    ),
  ),
  GoRoute(
    path: RoutePaths.bookingConfirmation,
    name: RouteNames.bookingConfirmation,
    builder: (context, state) => BookingConfirmationScreen(
      bookingId: state.pathParameters['bookingId']!,
    ),
  ),
];
