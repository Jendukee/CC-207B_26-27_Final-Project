// Unit tests for helpers added to the shared models in the UI audit:
// Booking.displayStatus (#14) and Payment.methodLabel (#15).
// Run with: flutter test test/shared

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

Booking _booking(BookingStatus status, {DateTime? expiresAt}) => Booking(
  id: 'b1',
  referenceNo: 'O150-TEST',
  customerId: 'c1',
  status: status,
  paymentOption: PaymentOption.half,
  totalAmount: 3500,
  amountPaid: 0,
  pickupDate: DateTime(2026, 12, 23),
  eventDate: DateTime(2026, 12, 24),
  returnDate: DateTime(2026, 12, 25),
  expiresAt: expiresAt,
);

void main() {
  final now = DateTime(2026, 11, 24, 12);

  group('Booking.displayStatus', () {
    test('pending past its deadline shows as expired', () {
      final late = _booking(
        BookingStatus.pending,
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(late.displayStatus(now), BookingStatus.expired);
    });

    test('pending before its deadline, or with none, stays pending', () {
      final early = _booking(
        BookingStatus.pending,
        expiresAt: now.add(const Duration(hours: 1)),
      );
      expect(early.displayStatus(now), BookingStatus.pending);
      expect(
        _booking(BookingStatus.pending).displayStatus(now),
        BookingStatus.pending,
      );
    });

    test('other statuses are unchanged', () {
      final reserved = _booking(
        BookingStatus.reserved,
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(reserved.displayStatus(now), BookingStatus.reserved);
    });
  });

  test('Payment.methodLabel uses words', () {
    Payment payment(String method) => Payment(
      bookingId: 'b1',
      amount: 100,
      kind: PaymentKind.full,
      method: method,
    );
    expect(payment('gcash').methodLabel, 'GCash');
    expect(payment('bank').methodLabel, 'Bank transfer');
    expect(payment('cash').methodLabel, 'Cash');
    expect(payment('other').methodLabel, 'other');
  });
}
