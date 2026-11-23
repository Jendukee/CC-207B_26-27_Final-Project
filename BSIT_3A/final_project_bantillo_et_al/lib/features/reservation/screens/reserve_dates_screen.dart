// Reservation step 1: pick the event date for the item.
// Will compute pickup (event - 1 day) and return (event + 1 day), and run a
// conflict check against blocked dates before letting the customer continue.
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Choose Event Date" screen (see the file header for the plan).
class ReserveDatesScreen extends StatelessWidget {
  /// Creates the "Choose Event Date" screen for the given [itemId].
  const ReserveDatesScreen({super.key, required this.itemId});

  /// Path parameter from the route (see reservation_routes.dart).
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Event Date')),
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
