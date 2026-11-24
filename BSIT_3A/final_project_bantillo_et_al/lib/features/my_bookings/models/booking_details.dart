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

  /// Only pending or reserved bookings can be cancelled.
  bool get canCancel =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.reserved;

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
