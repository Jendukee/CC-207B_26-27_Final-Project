// Reservation step 2: confirm or enter body measurements (inches).
// Will prefill from the customer's saved measurements, validate ranges with
// Validators.numberRange, and ask for measurement consent.
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Your Measurements" screen (see the file header for the plan).
class ReserveMeasurementsScreen extends StatelessWidget {
  /// Creates the "Your Measurements" screen for the given [itemId].
  const ReserveMeasurementsScreen({super.key, required this.itemId});

  /// Path parameter from the route (see reservation_routes.dart).
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Measurements')),
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
