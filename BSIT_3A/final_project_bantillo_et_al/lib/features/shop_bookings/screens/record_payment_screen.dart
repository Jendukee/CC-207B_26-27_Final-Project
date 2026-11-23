// Record payment form: amount, kind (full / down / balance) and method.
// Will validate the amount against the remaining balance before saving.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Record Payment" screen (see the file header for the plan).
class RecordPaymentScreen extends StatelessWidget {
  /// Creates the "Record Payment" screen for the given [bookingId].
  const RecordPaymentScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see shop_bookings_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
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
