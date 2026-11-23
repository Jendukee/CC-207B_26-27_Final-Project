// Unit tests for the shop_bookings feature that need no Supabase
// connection: Record Payment amount rules (PaymentRules), staff status
// rules (BookingRules) and database error messages.
// Run with: flutter test test/features/shop_bookings

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/features/shop_bookings/models/booking_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/payment_rules.dart';
import 'package:orange150_rental/features/shop_bookings/services/shop_bookings_service.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// A booking with only the fields these rules look at.
Booking _booking({
  BookingStatus status = BookingStatus.pending,
  double total = 3500,
  double paid = 0,
  DateTime? expiresAt,
}) {
  return Booking(
    id: 'b1',
    referenceNo: 'O150-TEST',
    customerId: 'c1',
    status: status,
    paymentOption: PaymentOption.half,
    totalAmount: total,
    amountPaid: paid,
    pickupDate: DateTime(2026, 12, 23),
    eventDate: DateTime(2026, 12, 24),
    returnDate: DateTime(2026, 12, 25),
    expiresAt: expiresAt,
  );
}

void main() {
  group('PaymentRules.validateAmount', () {
    String? check(String text, PaymentKind kind, {double paid = 0}) =>
        PaymentRules.validateAmount(text, kind: kind, total: 3500, paid: paid);

    test('rejects empty, non-numbers, zero and negatives', () {
      expect(check('', PaymentKind.full), 'Enter the amount paid.');
      expect(check('abc', PaymentKind.full), contains('Enter a number'));
      expect(
        check('0', PaymentKind.balance, paid: 1750),
        'Enter an amount greater than 0.',
      );
      expect(
        check('-5', PaymentKind.balance, paid: 1750),
        'Enter an amount greater than 0.',
      );
    });

    test('rejects more than 2 decimal places', () {
      expect(
        check('100.555', PaymentKind.balance, paid: 1750),
        'Use at most 2 decimal places.',
      );
    });

    test('full payment must equal the total', () {
      expect(check('3500', PaymentKind.full), isNull);
      expect(check('₱3,500.00', PaymentKind.full), isNull);
      expect(check('3000', PaymentKind.full), contains('must equal the total'));
    });

    test('down payment must be exactly 50%', () {
      expect(check('1750', PaymentKind.down), isNull);
      expect(check('1000', PaymentKind.down), contains('exactly 50%'));
    });

    test('down payment rounds to the centavo like SQL round(total*0.5, 2)', () {
      // 999.99 / 2 = 499.995 -> 500.00 (half rounds away from zero).
      expect(PaymentRules.downPaymentFor(999.99), 500);
      expect(
        PaymentRules.validateAmount(
          '500.00',
          kind: PaymentKind.down,
          total: 999.99,
          paid: 0,
        ),
        isNull,
      );
    });

    test('cannot pay more than the balance', () {
      expect(
        check('2000', PaymentKind.balance, paid: 1750),
        contains('more than the balance'),
      );
    });

    test('balance payments may be partial, but need an earlier payment', () {
      expect(check('500', PaymentKind.balance, paid: 1750), isNull);
      expect(check('1750', PaymentKind.balance, paid: 1750), isNull);
      expect(check('500', PaymentKind.balance), contains('first'));
    });

    test('full or down are not allowed once something is paid', () {
      expect(
        check('1750', PaymentKind.down, paid: 1750),
        contains('already has a payment'),
      );
    });
  });

  group('PaymentRules helpers', () {
    test('allowedKinds depends on whether anything is paid', () {
      expect(PaymentRules.allowedKinds(paid: 0), [
        PaymentKind.full,
        PaymentKind.down,
      ]);
      expect(PaymentRules.allowedKinds(paid: 100), [PaymentKind.balance]);
    });

    test('suggestedAmount fills the form', () {
      expect(
        PaymentRules.suggestedAmount(PaymentKind.full, total: 3500, paid: 0),
        3500,
      );
      expect(
        PaymentRules.suggestedAmount(PaymentKind.down, total: 3500, paid: 0),
        1750,
      );
      expect(
        PaymentRules.suggestedAmount(
          PaymentKind.balance,
          total: 3500,
          paid: 1750,
        ),
        1750,
      );
    });

    test('balance uses centavos (no floating point drift)', () {
      expect(PaymentRules.balance(total: 0.3, paid: 0.1), 0.2);
      expect(PaymentRules.balance(total: 100, paid: 150), 0);
    });
  });

  group('BookingRules', () {
    final now = DateTime(2026, 11, 23, 12);

    test('pending past expires_at shows as expired', () {
      final late = _booking(expiresAt: now.subtract(const Duration(hours: 1)));
      final live = _booking(expiresAt: now.add(const Duration(hours: 1)));
      expect(
        BookingRules.effectiveStatus(late, now: now),
        BookingStatus.expired,
      );
      expect(
        BookingRules.effectiveStatus(live, now: now),
        BookingStatus.pending,
      );
      expect(BookingRules.canRecordPayment(late, now: now), isFalse);
      expect(BookingRules.canCancel(late), isTrue);
    });

    test('buttons follow the status rules', () {
      final reservedOwing = _booking(
        status: BookingStatus.reserved,
        paid: 1750,
      );
      final reservedPaid = _booking(status: BookingStatus.reserved, paid: 3500);
      final rentedOut = _booking(status: BookingStatus.rentedOut, paid: 3500);
      final returned = _booking(status: BookingStatus.returned, paid: 3500);

      expect(BookingRules.canRecordPayment(reservedOwing, now: now), isTrue);
      expect(BookingRules.canRecordPayment(reservedPaid, now: now), isFalse);
      expect(BookingRules.canMarkPickedUp(reservedOwing), isTrue);
      expect(BookingRules.canMarkReturned(rentedOut), isTrue);
      expect(BookingRules.canCancel(rentedOut), isFalse);
      expect(BookingRules.canCancel(returned), isFalse);
      expect(BookingRules.canMarkPickedUp(returned), isFalse);
    });

    test('payment status label', () {
      expect(BookingRules.paymentStatusLabel(_booking()), 'Unpaid');
      expect(
        BookingRules.paymentStatusLabel(_booking(paid: 1750)),
        'Partially paid',
      );
      expect(
        BookingRules.paymentStatusLabel(_booking(paid: 3500)),
        'Paid in full',
      );
    });
  });

  group('ShopBookingsService.friendlyError', () {
    test('shows our SQL messages, also when wrapped in raw JSON', () {
      const plain = PostgrestException(
        message: 'Enter an amount greater than 0.',
        code: 'P0001',
      );
      const wrapped = PostgrestException(
        message:
            '{"code":"P0001","message":"Record a full or down payment '
            'first.","details":null,"hint":null}',
        code: '400',
      );
      expect(
        ShopBookingsService.friendlyError(plain),
        'Enter an amount greater than 0.',
      );
      expect(
        ShopBookingsService.friendlyError(wrapped),
        'Record a full or down payment first.',
      );
    });

    test('date conflict shows the agreed message', () {
      const conflict = PostgrestException(
        message: 'conflicting key value violates exclusion constraint',
        code: '23P01',
      );
      expect(
        ShopBookingsService.friendlyError(conflict),
        ShopBookingsService.dateConflictMessage,
      );
    });

    test('missing grant explains which migration to run', () {
      const denied = PostgrestException(
        message:
            '{"code":"42501","message":"permission denied for table '
            'bookings"}',
        code: '403',
      );
      expect(
        ShopBookingsService.friendlyError(denied),
        contains('0006_table_grants.sql'),
      );
    });
  });
}
