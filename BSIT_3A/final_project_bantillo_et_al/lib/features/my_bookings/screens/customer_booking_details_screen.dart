// Customer booking details: item, dates, payments, balance and status.
// Will allow cancelling a pending or reserved booking (with a confirm dialog).
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Booking Details" screen (see the file header for the plan).
class CustomerBookingDetailsScreen extends StatelessWidget {
  /// Creates the "Booking Details" screen for the given [bookingId].
  const CustomerBookingDetailsScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see my_bookings_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'TODO: Member 2 builds this\n(bookingId: $bookingId)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
