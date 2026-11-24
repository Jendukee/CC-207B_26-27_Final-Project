// Plain-language status text for the customer's "Booking status" card
// (customer redesign 2, Phase 1): the status in words and what to do next.
// Plain Dart so it can be unit tested. Moved out of the details screen; the
// GCash number is now on the "How to pay" card instead of in this text.
//
// H2 match between the system and the real world, H1 visibility of system
// status.
//
// OWNER: Member 2.

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

/// Status wording for customers.
abstract final class CustomerStatusText {
  /// The status in words.
  static String words(BookingStatus status) => switch (status) {
    BookingStatus.pending => 'Waiting for your payment',
    BookingStatus.reserved => 'Your dates are reserved',
    BookingStatus.rentedOut => 'You have the item',
    BookingStatus.returned => 'Returned, all done',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.expired => 'Expired, not paid in time',
  };

  /// What to do next, e.g. "Pay ₱875.00 by Dec 8, 2026, 11:59 PM to
  /// confirm your reservation." [now] can be fixed in tests.
  static String nextStep(Booking b, [DateTime? now]) {
    final payNow = PaymentPlan.dueNow(b.totalAmount, b.paymentOption);
    final deadline = b.expiresAt;
    return switch (b.displayStatus(now)) {
      BookingStatus.pending =>
        'Pay ${Formatters.peso(payNow)}'
            '${deadline == null ? '' : ' by ${Formatters.dateTime(deadline)}'}'
            ' to confirm your reservation.',
      BookingStatus.reserved =>
        'Reserved! Pick up on ${Formatters.date(b.pickupDate)} at the shop.'
            '${b.balance > 0 ? ' Bring the balance of ${Formatters.peso(b.balance)}.' : ''}',
      BookingStatus.rentedOut =>
        'Enjoy your event! Please return it by '
            '${Formatters.date(b.returnDate)}.',
      BookingStatus.returned => 'Returned. Thank you for renting with us!',
      BookingStatus.cancelled => 'This booking was cancelled.',
      BookingStatus.expired =>
        'This request expired because it was not paid in time.',
    };
  }
}
