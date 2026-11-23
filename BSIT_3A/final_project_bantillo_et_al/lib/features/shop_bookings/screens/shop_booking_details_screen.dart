// Staff booking details: customer, item, dates, measurements snapshot, payments.
// Will offer actions by status: confirm (reserve), record payment, release
// checklist, return checklist, cancel.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Booking Details" screen (see the file header for the plan).
class ShopBookingDetailsScreen extends StatelessWidget {
  /// Creates the "Booking Details" screen for the given [bookingId].
  const ShopBookingDetailsScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see shop_bookings_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'TODO: Member 3 builds this\n(bookingId: $bookingId)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
