// Booking status rules for the staff screens, in plain Dart so they can be
// unit tested. They decide what status to SHOW and which buttons to show.
// The database (update_booking_status / record_payment in 0002) enforces
// the same rules again.
//
//   pending  --full or 50% down payment-->  reserved
//   reserved --release checklist + balance paid-->  rented_out
//   rented_out --return checklist-->  returned
//   pending / reserved --staff cancel-->  cancelled
//   pending past expires_at is SHOWN as expired.
//
// OWNER: Member 3.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// Pure functions about a booking's status.
abstract final class BookingRules {
  /// True when a pending booking is past its expires_at.
  static bool isPastExpiry(Booking booking, {DateTime? now}) {
    final expiresAt = booking.expiresAt;
    return booking.status == BookingStatus.pending &&
        expiresAt != null &&
        expiresAt.isBefore(now ?? DateTime.now());
  }

  /// The status to display: a pending booking past expires_at shows as
  /// expired even if the database row still says pending.
  static BookingStatus effectiveStatus(Booking booking, {DateTime? now}) =>
      isPastExpiry(booking, now: now) ? BookingStatus.expired : booking.status;

  /// "Record payment" is shown for live pending bookings and for reserved
  /// bookings that still have a balance.
  static bool canRecordPayment(Booking booking, {DateTime? now}) {
    final status = effectiveStatus(booking, now: now);
    if (status == BookingStatus.pending) return true;
    return status == BookingStatus.reserved && booking.balance > 0;
  }

  /// "Mark picked up" (opens the release checklist) for reserved bookings.
  static bool canMarkPickedUp(Booking booking) =>
      booking.status == BookingStatus.reserved;

  /// "Mark returned" (opens the return checklist) for rented out bookings.
  static bool canMarkReturned(Booking booking) =>
      booking.status == BookingStatus.rentedOut;

  /// Staff may cancel pending (including expired-looking) and reserved
  /// bookings.
  static bool canCancel(Booking booking) =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.reserved;

  /// Short payment summary for list cards.
  static String paymentStatusLabel(Booking booking) {
    if (booking.totalAmount > 0 && booking.balance <= 0) return 'Paid in full';
    if (booking.amountPaid > 0) return 'Partially paid';
    return 'Unpaid';
  }
}
