// Routes owned by the reservation feature. Full screen (outside the tab
// shell) so the 3-step flow has no tab bar. Sign-in required (auth_guard).
//
// Typical flow from Item Details:
//   context.pushNamed(RouteNames.reserveDates, pathParameters: {'itemId': id});
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/screens/booking_confirmation_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_dates_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_measurements_screen.dart';
import 'package:orange150_rental/features/reservation/screens/reserve_review_screen.dart';

/// /reserve/:itemId/dates, /reserve/:itemId/measurements,
/// /reserve/:itemId/review and /booking-confirmation/:bookingId
final List<RouteBase> reservationRoutes = [
  GoRoute(
    path: RoutePaths.reserveDates,
    name: RouteNames.reserveDates,
    builder: (context, state) =>
        ReserveDatesScreen(itemId: state.pathParameters['itemId']!),
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
    ),
  ),
];
