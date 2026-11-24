// Routes owned by the my_bookings feature (My Bookings tab, customer shell).
// Sign-in required (core/router/auth_guard.dart).
//
// /my-bookings?tab=to-pay opens a given order tab (customer redesign);
// keys: to-pay, to-pick-up, rented, completed, cancelled.
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/my_bookings/screens/customer_booking_details_screen.dart';
import 'package:orange150_rental/features/my_bookings/screens/my_bookings_screen.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

/// /my-bookings and /my-bookings/:bookingId
final List<RouteBase> myBookingsRoutes = [
  GoRoute(
    path: RoutePaths.myBookings,
    name: RouteNames.myBookings,
    builder: (context, state) => MyBookingsScreen(
      initialTab: CustomerBookingTab.fromKey(state.uri.queryParameters['tab']),
    ),
    routes: [
      GoRoute(
        path: RoutePaths.customerBookingDetails,
        name: RouteNames.customerBookingDetails,
        builder: (context, state) => CustomerBookingDetailsScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
    ],
  ),
];
