// Reports (staff/owner): revenue per month, bookings by status and most
// rented items, drawn with fl_chart, for a chosen date range.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Reports" screen (see the file header for the plan).
class ReportsScreen extends StatelessWidget {
  /// Creates the "Reports" screen.
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
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
