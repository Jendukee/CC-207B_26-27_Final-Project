// Colored chip showing a booking status. Always shows the text label next to
// the color (accessibility).
//
// UI audit #14: it now uses the shared StatusChip, so a booking has the
// SAME color for the customer and for staff (Pending orange, Reserved
// maroon, Rented Out deep red, Returned green, Cancelled / Expired grey).
// Pass booking.displayStatus() so an unpaid request past its deadline
// shows as Expired.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// The status chip used on My Bookings.
class BookingStatusBadge extends StatelessWidget {
  /// Creates the badge for [status].
  const BookingStatusBadge({super.key, required this.status});

  /// Usually booking.displayStatus().
  final BookingStatus status;

  @override
  Widget build(BuildContext context) => StatusChip.booking(status);
}
