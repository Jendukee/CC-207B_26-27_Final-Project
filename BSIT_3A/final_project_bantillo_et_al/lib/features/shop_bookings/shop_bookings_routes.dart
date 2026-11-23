// Routes owned by the shop_bookings feature (Bookings tab, staff shell).
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_bookings/screens/record_payment_screen.dart';
import 'package:orange150_rental/features/shop_bookings/screens/shop_booking_details_screen.dart';
import 'package:orange150_rental/features/shop_bookings/screens/shop_bookings_list_screen.dart';

/// /shop/bookings, /shop/bookings/:bookingId, /shop/bookings/:bookingId/payment
final List<RouteBase> shopBookingsRoutes = [
  GoRoute(
    path: RoutePaths.shopBookings,
    name: RouteNames.shopBookings,
    builder: (context, state) => const ShopBookingsListScreen(),
    routes: [
      GoRoute(
        path: RoutePaths.shopBookingDetails,
        name: RouteNames.shopBookingDetails,
        builder: (context, state) => ShopBookingDetailsScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.recordPayment,
        name: RouteNames.recordPayment,
        builder: (context, state) =>
            RecordPaymentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
    ],
  ),
];
