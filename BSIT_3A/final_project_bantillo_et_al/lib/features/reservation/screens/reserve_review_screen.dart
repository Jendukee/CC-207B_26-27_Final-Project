// Reservation step 3: summary, payment option (full / 50% down) and e-contract.
// Will show the rental terms, require the customer to acknowledge them, then
// submit the pending booking and go to BookingConfirmation.
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Review & Contract" screen (see the file header for the plan).
class ReserveReviewScreen extends StatelessWidget {
  /// Creates the "Review & Contract" screen for the given [itemId].
  const ReserveReviewScreen({super.key, required this.itemId});

  /// Path parameter from the route (see reservation_routes.dart).
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Contract')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'TODO: Member 2 builds this\n(itemId: $itemId)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
