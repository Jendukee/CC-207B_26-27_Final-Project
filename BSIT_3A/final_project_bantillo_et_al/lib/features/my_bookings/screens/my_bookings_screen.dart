// My Bookings: the signed-in customer's bookings, newest first, each with a
// StatusChip. Will use AsyncListView and open CustomerBookingDetails.
//
// OWNER: Member 2. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "My Bookings" screen (see the file header for the plan).
class MyBookingsScreen extends StatelessWidget {
  /// Creates the "My Bookings" screen.
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO: Member 2 builds this',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
