// Routes owned by the reservation feature. Full screen (outside the tab
// shell), sign-in required (auth_guard: everything under /reserve).
//
// Customer redesign (Phase 1): the flow is now
//   Item details -> Reserve sheet (date) -> Checkout -> Request submitted
// Item details opens the checkout BY PATH:
//   /reserve/:itemId/checkout?date=yyyy-MM-dd
// The old step routes keep their paths (routes are never renamed):
//   * /reserve/:itemId/dates now redirects to the item page, where the
//     Reserve sheet picks the date
//   * /reserve/:itemId/measurements and /review still exist for old links;
//     without their in-memory draft they send the customer back to start.
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/screens/booking_confirmation_screen.dart';
import 'package:orange150_rental/features/reservation/screens/checkout_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_dates_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_measurements_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_review_screen.dart';

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
  GoRoute(
    path: RoutePaths.reserveDates,
    name: RouteNames.reserveDates,
    // Replaced by the Reserve sheet on the item page.
    redirect: (context, state) =>
        '${RoutePaths.browse}/item/${state.pathParameters['itemId']}',
    builder: (context, state) =>
        ReserveDatesScreen(itemId: state.pathParameters['itemId']!),
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
    path: RoutePaths.reserveMeasurements,
    name: RouteNames.reserveMeasurements,
    builder: (context, state) {
      final extra = state.extra;
      return ReserveMeasurementsScreen(
        itemId: state.pathParameters['itemId']!,
        draft: extra is ReservationDraft ? extra : null,
      );
    },
  ),
  GoRoute(
    path: RoutePaths.reserveReview,
    name: RouteNames.reserveReview,
    builder: (context, state) {
      final extra = state.extra;
      return ReserveReviewScreen(
        itemId: state.pathParameters['itemId']!,
        draft: extra is ReservationDraft ? extra : null,
      );
    },
  ),
  GoRoute(
    path: RoutePaths.bookingConfirmation,
    name: RouteNames.bookingConfirmation,
    builder: (context, state) => BookingConfirmationScreen(
      bookingId: state.pathParameters['bookingId']!,
      // Payment method chosen at checkout (for the payment instructions).
      method: state.uri.queryParameters['method'],
    ),
  ),
];
