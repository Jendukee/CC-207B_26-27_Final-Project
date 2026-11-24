// Shared formatting helpers for the my_bookings feature.
//
// OWNER: Member 2.

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// Payment deadline line for a pending booking (UI audit #8), e.g.
/// "Pay by Nov 26, 2026 3:30 PM", or a notice once it has passed.
/// Null for bookings that are not pending or have no deadline.
String? payByText(Booking b, {DateTime? now}) {
  final deadline = b.expiresAt;
  if (b.status != BookingStatus.pending || deadline == null) return null;
  if (deadline.isBefore(now ?? DateTime.now())) {
    return 'Payment deadline passed (${Formatters.dateTime(deadline)})';
  }
  return 'Pay by ${Formatters.dateTime(deadline)}';
}

// UI audit #23: these now call the shared core Formatters, so dates and
// pesos look the same on every screen of the app.

/// e.g. "Dec 5, 2026".
String formatDate(DateTime d) => Formatters.date(d);

/// Same as [formatDate] but shows an en dash for null.
String formatDateOrDash(DateTime? d) => d == null ? '–' : formatDate(d);

/// e.g. "₱1,500.00".
String formatPeso(num amount) => Formatters.peso(amount);
