// Staff bookings list: all bookings with search by reference/customer and
// filters by status (StatusChip). Opens ShopBookingDetails.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Bookings" screen (see the file header for the plan).
class ShopBookingsListScreen extends StatelessWidget {
  /// Creates the "Bookings" screen.
  const ShopBookingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO: Member 3 builds this',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
