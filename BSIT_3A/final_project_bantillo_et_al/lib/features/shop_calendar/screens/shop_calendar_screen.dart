// Staff calendar (table_calendar): month view of pickups, events and returns.
// Tapping a day lists that day's bookings and opens ShopBookingDetails.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Calendar" screen (see the file header for the plan).
class ShopCalendarScreen extends StatelessWidget {
  /// Creates the "Calendar" screen.
  const ShopCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
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
