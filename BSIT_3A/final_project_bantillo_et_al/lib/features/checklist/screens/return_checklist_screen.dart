// Return checklist: verify inclusions came back, record damage notes, photos
// and any penalty amount, then mark the booking Returned.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Return Checklist" screen (see the file header for the plan).
class ReturnChecklistScreen extends StatelessWidget {
  /// Creates the "Return Checklist" screen for the given [bookingId].
  const ReturnChecklistScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see checklist_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return Checklist')),
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
