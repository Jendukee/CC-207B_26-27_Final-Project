// Unit tests for skeleton code that needs no Supabase connection:
// shared validators, formatters and booking status mapping.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/shared/models/app_user.dart';
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

    // Phone rules changed in the UI audit: only 09XXXXXXXXX is accepted.
    // Full cases are in test/core/phone_validator_test.dart.
    test('phone accepts only 09XXXXXXXXX', () {
      expect(Validators.phone('09171234567'), isNull);
      expect(Validators.phone('0917 123 4567'), isNotNull);
      expect(Validators.phone('+639171234567'), isNotNull);
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

  test('auth guard sends staff to the Dashboard, not customer pages', () {
    const staff = AppUser(id: 's1', role: UserRole.staff);
    const customer = AppUser(id: 'c1', role: UserRole.customer);

    expect(AuthGuard.destinationFor(staff, '/profile'), '/shop/dashboard');
    expect(AuthGuard.destinationFor(staff, null), '/shop/dashboard');
    expect(AuthGuard.destinationFor(staff, '/shop/bookings'), '/shop/bookings');
    expect(AuthGuard.destinationFor(customer, '/my-bookings'), '/my-bookings');
    expect(AuthGuard.destinationFor(customer, '/shop/dashboard'), '/browse');
  });

  // Single login: right after signing in, staff always land on the
  // Dashboard (destinationFor above still serves Splash deep links).
  test('after sign in, staff go to the Dashboard even with a /shop link', () {
    const staff = AppUser(id: 's1', role: UserRole.staff);
    expect(AuthGuard.afterSignIn(staff, '/shop/bookings'), '/shop/dashboard');
  });
}
