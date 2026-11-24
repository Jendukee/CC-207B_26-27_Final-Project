// A booking with its items, payments and checklist dates, as shown on the
// order-style details screen (customer redesign, Phase 1).
//
// The timeline steps:
//   Requested  bookings.created_at
//   Reserved   first payment (a full or 50% payment reserves the booking)
//   Picked up  the release checklist was saved
//   Returned   the return checklist was saved
//
// OWNER: Member 2.

import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// One step of the booking timeline.
class TimelineStep {
  /// Creates a step; [date] is null while not reached yet.
  const TimelineStep(this.label, this.date);

  /// "Requested", "Reserved", "Picked up" or "Returned".
  final String label;

  /// When it happened, or null.
  final DateTime? date;

  /// True once reached.
  bool get done => date != null;
}

class BookingDetails {
  const BookingDetails({
    required this.myBooking,
    required this.payments,
    this.checklistDates = const {},
  });

  final MyBooking myBooking;
  final List<Payment> payments;

  /// 'release' / 'return' -> when that checklist was saved.
  final Map<String, DateTime> checklistDates;

  Booking get booking => myBooking.booking;
  List<Item> get items => myBooking.items;

  /// Phase 3: the customer may cancel ONLY while the booking is Pending
  /// (not paid yet). Once Reserved the reservation fee is non-refundable
  /// (rental terms 2 and 9), so only staff can cancel. A pending booking
  /// past its payment deadline shows as Expired, so it has no Cancel
  /// either. The database (cancel_my_booking, 0013) checks the same rule.
  bool get canCancel => customerCanCancel(booking);

  /// True when Cancel is hidden because the booking is Reserved: the
  /// details screen shows [nonRefundableNotice] instead.
  bool get showNonRefundableNotice => booking.status == BookingStatus.reserved;

  /// Shown instead of Cancel on a Reserved booking.
  static const String nonRefundableNotice =
      'Reservations are non-refundable and cannot be cancelled. Contact the '
      'shop for concerns.';

  /// The cancel rule as a pure function, so it can be tested. [now] can be
  /// fixed in tests.
  static bool customerCanCancel(Booking booking, [DateTime? now]) =>
      booking.displayStatus(now) == BookingStatus.pending;

  /// The four timeline steps, in order.
  List<TimelineStep> get timeline => [
    TimelineStep('Requested', booking.createdAt),
    TimelineStep(
      'Reserved',
      payments.isEmpty ? null : payments.first.createdAt,
    ),
    TimelineStep('Picked up', checklistDates['release']),
    TimelineStep('Returned', checklistDates['return']),
  ];

  /// Payment methods used so far, in words, e.g. "GCash, Cash".
  String get methodsUsed =>
      payments.map((p) => p.methodLabel).toSet().join(', ');
}
