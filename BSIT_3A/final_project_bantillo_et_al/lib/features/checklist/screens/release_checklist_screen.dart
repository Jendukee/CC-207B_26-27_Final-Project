// Release checklist (pickup day): /shop/checklist/release/:bookingId.
// Tick every garment and inclusion handed over, note the condition, take
// photos, collect any balance, then "Release items" moves the booking to
// Rented Out. The form itself lives in checklist_screen.dart.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/features/checklist/models/checklist_kind.dart';
import 'package:orange150_rental/features/checklist/screens/checklist_screen.dart';

/// The "Release Checklist" screen.
class ReleaseChecklistScreen extends StatelessWidget {
  /// Creates the screen for the given [bookingId].
  const ReleaseChecklistScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see checklist_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      ChecklistScreen(bookingId: bookingId, kind: ChecklistKind.release);
}
