// Routes owned by the my_bookings feature (My Bookings tab, customer shell).
// Combined into the customer StatefulShellRoute by core/router/app_router.dart.
// Sign-in required (auth_guard).
//
// OWNER: Member 2.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/my_bookings/screens/customer_booking_details_screen.dart';
import 'package:orange150_rental/features/my_bookings/screens/my_bookings_screen.dart';

/// /my-bookings and /my-bookings/:bookingId
final List<RouteBase> myBookingsRoutes = [
  GoRoute(
    path: RoutePaths.myBookings,
    name: RouteNames.myBookings,
    builder: (context, state) => const MyBookingsScreen(),
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