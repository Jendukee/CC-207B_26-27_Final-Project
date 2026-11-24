// Unit tests for CustomerBookingTab (customer redesign, Phase 1): which
// My Bookings tab each booking belongs to, link keys and counts.
// Run with: flutter test test/shared

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

Booking _b(BookingStatus status, {DateTime? expiresAt}) => Booking(
  id: 'b',
  referenceNo: 'O150-T',
  customerId: 'c',
  status: status,
  paymentOption: PaymentOption.half,
  totalAmount: 3000,
  amountPaid: 0,
  pickupDate: DateTime(2026, 12, 23),
  eventDate: DateTime(2026, 12, 24),
  returnDate: DateTime(2026, 12, 25),
  expiresAt: expiresAt,
);

void main() {
  final now = DateTime(2026, 11, 24, 12);

  test('each status goes to its tab', () {
    expect(
      CustomerBookingTab.of(_b(BookingStatus.pending), now),
      CustomerBookingTab.toPay,
    );
    expect(
      CustomerBookingTab.of(_b(BookingStatus.reserved), now),
      CustomerBookingTab.toPickUp,
    );
    expect(
      CustomerBookingTab.of(_b(BookingStatus.rentedOut), now),
      CustomerBookingTab.rented,
    );
    expect(
      CustomerBookingTab.of(_b(BookingStatus.returned), now),
      CustomerBookingTab.completed,
    );
    expect(
      CustomerBookingTab.of(_b(BookingStatus.cancelled), now),
      CustomerBookingTab.cancelled,
    );
    expect(
      CustomerBookingTab.of(_b(BookingStatus.expired), now),
      CustomerBookingTab.cancelled,
    );
  });

  test('pending past its payment deadline counts as cancelled', () {
    final late = _b(
      BookingStatus.pending,
      expiresAt: now.subtract(const Duration(hours: 1)),
    );
    expect(CustomerBookingTab.of(late, now), CustomerBookingTab.cancelled);
  });

  test('link keys round-trip, unknown keys open To Pay', () {
    for (final tab in CustomerBookingTab.values) {
      expect(CustomerBookingTab.fromKey(tab.key), tab);
    }
    expect(CustomerBookingTab.fromKey('nope'), CustomerBookingTab.toPay);
    expect(CustomerBookingTab.fromKey(null), CustomerBookingTab.toPay);
  });

  test('countAll counts every tab, including empty ones', () {
    final counts = CustomerBookingTab.countAll([
      _b(BookingStatus.pending),
      _b(BookingStatus.pending),
      _b(BookingStatus.returned),
    ], now);
    expect(counts[CustomerBookingTab.toPay], 2);
    expect(counts[CustomerBookingTab.completed], 1);
    expect(counts[CustomerBookingTab.rented], 0);
  });
}
