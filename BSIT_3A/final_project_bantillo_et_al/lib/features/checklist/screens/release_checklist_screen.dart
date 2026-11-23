// Release checklist (pickup day): tick each inclusion handed over, note the
// item's condition, take photos (image_picker) and mark the booking Rented Out.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Release Checklist" screen (see the file header for the plan).
class ReleaseChecklistScreen extends StatelessWidget {
  /// Creates the "Release Checklist" screen for the given [bookingId].
  const ReleaseChecklistScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see checklist_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Release Checklist')),
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
