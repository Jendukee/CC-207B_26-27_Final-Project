// Unit tests for skeleton code that needs no Supabase connection:
// shared validators, formatters and booking status mapping.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

void main() {
  group('Validators', () {
    test('required rejects blank text', () {
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('Ana'), isNull);
    });

    test('email checks format', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('ana@example.com'), isNull);
    });

    test('phone accepts PH mobile formats', () {
      expect(Validators.phone('0917 123 4567'), isNull);
      expect(Validators.phone('+639171234567'), isNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('', isRequired: false), isNull);
    });

    test('numberRange enforces bounds', () {
      expect(Validators.numberRange('30', min: 15, max: 70), isNull);
      expect(Validators.numberRange('5', min: 15, max: 70), isNotNull);
      expect(Validators.numberRange('abc', min: 15, max: 70), isNotNull);
    });
  });

  test('peso formatter', () {
    expect(Formatters.peso(1500), '₱1,500.00');
  });

  test('booking status maps database values', () {
    expect(BookingStatus.fromDb('rented_out'), BookingStatus.rentedOut);
    expect(BookingStatus.rentedOut.label, 'Rented Out');
    expect(BookingStatus.reserved.blocksDates, isTrue);
    expect(BookingStatus.pending.blocksDates, isFalse);
  });

  test('auth guard only accepts in-app return paths', () {
    expect(AuthGuard.safeFrom('/my-bookings'), '/my-bookings');
    expect(AuthGuard.safeFrom('https://evil.example'), isNull);
    expect(AuthGuard.safeFrom('//evil.example'), isNull);
    expect(AuthGuard.safeFrom('/login'), isNull);
  });
}
