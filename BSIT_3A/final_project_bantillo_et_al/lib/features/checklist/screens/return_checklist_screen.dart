// Return checklist (return day): /shop/checklist/return/:bookingId.
// Tick what came back (missing items may stay unticked), note condition
// and damage, take photos, enter any penalty, then "Mark returned" moves
// the booking to Returned and its items to Cleaning / Repair.
// The form itself lives in checklist_screen.dart.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/features/checklist/models/checklist_kind.dart';
import 'package:orange150_rental/features/checklist/screens/checklist_screen.dart';

/// The "Return Checklist" screen.
class ReturnChecklistScreen extends StatelessWidget {
  /// Creates the screen for the given [bookingId].
  const ReturnChecklistScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see checklist_routes.dart).
  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      ChecklistScreen(bookingId: bookingId, kind: ChecklistKind.returned);
}
