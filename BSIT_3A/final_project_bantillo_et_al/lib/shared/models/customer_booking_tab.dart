// The customer's booking tabs, like the order tabs of a shopping app
// (customer redesign, Phase 1). Used by My Bookings (the tabs) and by
// Profile (the shortcut icons with counts), so both always agree on which
// booking belongs where.
//
//   To Pay      pending, not past its payment deadline
//   To Pick Up  reserved
//   Rented      rented out
//   Completed   returned
//   Cancelled   cancelled, expired, or pending past its payment deadline
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// One of the five My Bookings tabs.
enum CustomerBookingTab {
  /// Waiting for the reservation fee.
  toPay('to-pay', 'To Pay'),

  /// Paid, waiting for pick-up.
  toPickUp('to-pick-up', 'To Pick Up'),

  /// With the customer now.
  rented('rented', 'Rented'),

  /// Returned.
  completed('completed', 'Completed'),

  /// Cancelled or expired.
  cancelled('cancelled', 'Cancelled');

  const CustomerBookingTab(this.key, this.label);

  /// Value used in links, e.g. /my-bookings?tab=to-pay.
  final String key;

  /// Tab text.
  final String label;

  /// The tab for a link value; unknown values open [toPay].
  static CustomerBookingTab fromKey(String? key) =>
      values.firstWhere((t) => t.key == key, orElse: () => toPay);

  /// The tab [booking] belongs to, using its DISPLAYED status (a pending
  /// request past its deadline counts as expired).
  static CustomerBookingTab of(Booking booking, [DateTime? now]) =>
      switch (booking.displayStatus(now)) {
        BookingStatus.pending => toPay,
        BookingStatus.reserved => toPickUp,
        BookingStatus.rentedOut => rented,
        BookingStatus.returned => completed,
        BookingStatus.cancelled || BookingStatus.expired => cancelled,
      };

  /// How many of [bookings] fall in each tab.
  static Map<CustomerBookingTab, int> countAll(
    Iterable<Booking> bookings, [
    DateTime? now,
  ]) {
    final counts = {for (final tab in values) tab: 0};
    for (final booking in bookings) {
      final tab = of(booking, now);
      counts[tab] = counts[tab]! + 1;
    }
    return counts;
  }
}
