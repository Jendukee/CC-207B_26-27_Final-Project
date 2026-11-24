// Plain-language status text for the staff "Booking status" card (customer
// redesign 2, Phase 1): the status in words and what staff do next.
// Plain Dart so it can be unit tested. No rules change: the status comes
// from BookingRules.effectiveStatus.
//
// H2 match between the system and the real world (shop words, not
// database values), H1 visibility of system status.
//
// OWNER: Member 3.

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

/// Status wording for staff.
abstract final class StaffStatusText {
  /// The status in words.
  static String words(BookingStatus status) => switch (status) {
    BookingStatus.pending => "Waiting for the customer's payment",
    BookingStatus.reserved => 'Dates reserved',
    BookingStatus.rentedOut => 'With the customer',
    BookingStatus.returned => 'Returned, completed',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.expired => 'Expired, not paid in time',
  };

  /// What happens next for [booking] shown as [status].
  static String nextStep(Booking booking, BookingStatus status) {
    final deadline = booking.expiresAt;
    return switch (status) {
      BookingStatus.pending =>
        'The customer pays '
            '${Formatters.peso(PaymentPlan.dueNow(booking.totalAmount, booking.paymentOption))}'
            '${deadline == null ? '' : ' by ${Formatters.dateTime(deadline)}'}'
            ' to confirm. Record the payment when it arrives.',
      BookingStatus.reserved =>
        booking.balance > 0
            ? 'Pick-up on ${Formatters.date(booking.pickupDate)}. Collect '
                  'the balance of ${Formatters.peso(booking.balance)}, then '
                  'release the items.'
            : 'Fully paid. Release the items on '
                  '${Formatters.date(booking.pickupDate)}.',
      BookingStatus.rentedOut =>
        'Return due ${Formatters.date(booking.returnDate)}. Check every '
            'item when it comes back.',
      BookingStatus.returned =>
        'Completed. The items went to Cleaning / Repair.',
      BookingStatus.cancelled =>
        'This booking was cancelled. No action needed.',
      BookingStatus.expired =>
        deadline == null
            ? 'This request expired without payment. No action needed.'
            : 'This request expired on ${Formatters.dateTime(deadline)} '
                  'without payment. No action needed.',
    };
  }
}
