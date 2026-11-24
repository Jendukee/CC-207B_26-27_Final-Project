// Phase 3: customers may cancel only while a booking is Pending. Once
// Reserved, Cancel is hidden and the non-refundable notice is shown.
// (Staff cancelling is tested in shop_bookings/payment_rules_test.dart.)
// Run with: flutter test test/features/my_bookings

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/my_bookings/models/booking_details.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/shared/models/booking.dart';

final _now = DateTime(2026, 11, 24, 12);

Booking _booking(String status, {DateTime? expiresAt}) => Booking.fromMap({
  'id': 'b1',
  'reference_no': 'O150-1',
  'customer_id': 'c1',
  'status': status,
  'payment_option': 'half',
  'total_amount': 2500,
  'amount_paid': status == 'pending' ? 0 : 1250,
  'pickup_date': '2026-12-23',
  'event_date': '2026-12-24',
  'return_date': '2026-12-25',
  'expires_at': expiresAt?.toUtc().toIso8601String(),
});

void main() {
  test('Pending (before the deadline) can be cancelled', () {
    final b = _booking(
      'pending',
      expiresAt: _now.add(const Duration(hours: 5)),
    );
    expect(BookingDetails.customerCanCancel(b, _now), isTrue);
  });

  test('Pending past its deadline shows as Expired: no Cancel', () {
    final b = _booking(
      'pending',
      expiresAt: _now.subtract(const Duration(minutes: 1)),
    );
    expect(BookingDetails.customerCanCancel(b, _now), isFalse);
  });

  test('Reserved and later statuses cannot be cancelled by the customer', () {
    for (final status in [
      'reserved',
      'rented_out',
      'returned',
      'cancelled',
      'expired',
    ]) {
      expect(
        BookingDetails.customerCanCancel(_booking(status), _now),
        isFalse,
        reason: status,
      );
    }
  });

  test('Reserved shows the non-refundable notice instead of Cancel', () {
    final reserved = BookingDetails(
      myBooking: MyBooking(booking: _booking('reserved'), items: const []),
      payments: const [],
    );
    expect(reserved.canCancel, isFalse);
    expect(reserved.showNonRefundableNotice, isTrue);
    expect(
      BookingDetails.nonRefundableNotice,
      'Reservations are non-refundable and cannot be cancelled. Contact the '
      'shop for concerns.',
    );

    final pending = BookingDetails(
      myBooking: MyBooking(booking: _booking('pending'), items: const []),
      payments: const [],
    );
    expect(pending.showNonRefundableNotice, isFalse);
  });
}
