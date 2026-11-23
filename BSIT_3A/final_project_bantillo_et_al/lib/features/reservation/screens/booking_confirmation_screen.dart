// Booking confirmation: shows the reference number, dates, amount due and
// payment instructions after a reservation is submitted, with a link to
// My Bookings.
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Booking Submitted" screen (see the file header for the plan).
class BookingConfirmationScreen extends StatelessWidget {
  /// Creates the "Booking Submitted" screen for the given [bookingId].
  const BookingConfirmationScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see reservation_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Submitted')),
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
