// Routes owned by the shop_bookings feature (Bookings tab, staff shell).
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// The list reads optional query parameters, so other features can open a
// filtered list by path only, for example:
//   context.go('/shop/bookings?status=reserved&from=2026-12-01&to=2026-12-31')
// Keys: status, q, from, to (see models/shop_booking_filter.dart).
//
// OWNER: Member 3.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking_filter.dart';
import 'package:orange150_rental/features/shop_bookings/screens/record_payment_screen.dart';
import 'package:orange150_rental/features/shop_bookings/screens/shop_booking_details_screen.dart';
import 'package:orange150_rental/features/shop_bookings/screens/shop_bookings_list_screen.dart';

/// /shop/bookings, /shop/bookings/:bookingId, /shop/bookings/:bookingId/payment
final List<RouteBase> shopBookingsRoutes = [
  GoRoute(
    path: RoutePaths.shopBookings,
    name: RouteNames.shopBookings,
    builder: (context, state) => ShopBookingsListScreen(
      initialFilter: ShopBookingFilter.fromQuery(state.uri.queryParameters),
    ),
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
