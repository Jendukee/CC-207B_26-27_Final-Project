// Unit tests for the dashboard date logic (DashboardDates): links to the
// filtered bookings list, days late and the per-booking detail line.
// No Supabase connection needed.
// Run with: flutter test test/features/shop_dashboard

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// A booking for an event on [event] (pickup the day before, return after).
Booking _booking(DateTime event, {DateTime? expiresAt}) => Booking(
  id: 'b1',
  referenceNo: 'O150-TEST',
  customerId: 'c1',
  status: BookingStatus.rentedOut,
  paymentOption: PaymentOption.full,
  totalAmount: 3500,
  amountPaid: 3500,
  pickupDate: event.subtract(const Duration(days: 1)),
  eventDate: event,
  returnDate: event.add(const Duration(days: 1)),
  expiresAt: expiresAt,
);

void main() {
  // Monday Nov 23, 2026, 3 PM local time.
  final now = DateTime(2026, 11, 23, 15);

  group('bookingsLink', () {
    test('pick-ups today = reserved, event tomorrow', () {
      expect(
        DashboardDates.bookingsLink(DashboardSection.pickupsToday, now),
        '/shop/bookings?status=reserved&from=2026-11-24&to=2026-11-24',
      );
    });

    test('returns today = rented out, event yesterday', () {
      expect(
        DashboardDates.bookingsLink(DashboardSection.returnsToday, now),
        '/shop/bookings?status=rented_out&from=2026-11-22&to=2026-11-22',
      );
    });

    test('overdue = rented out, event 2 or more days ago', () {
      expect(
        DashboardDates.bookingsLink(DashboardSection.overdueReturns, now),
        '/shop/bookings?status=rented_out&from=2000-01-01&to=2026-11-21',
      );
    });

    test('request cards open the pending list', () {
      expect(
        DashboardDates.bookingsLink(DashboardSection.expiringSoon, now),
        '/shop/bookings?status=pending',
      );
      expect(
        DashboardDates.bookingsLink(DashboardSection.newRequests, now),
        '/shop/bookings?status=pending',
      );
    });

    test('works across month ends', () {
      expect(
        DashboardDates.bookingsLink(
          DashboardSection.pickupsToday,
          DateTime(2026, 11, 30, 9),
        ),
        contains('from=2026-12-01'),
      );
    });
  });

  group('dates', () {
    test('startOfYesterday is midnight the day before', () {
      expect(DashboardDates.startOfYesterday(now), DateTime(2026, 11, 22));
    });

    test('daysLate counts whole days, never negative', () {
      expect(DashboardDates.daysLate(DateTime(2026, 11, 21), now), 2);
      expect(DashboardDates.daysLate(DateTime(2026, 11, 23), now), 0);
      expect(DashboardDates.daysLate(DateTime(2026, 11, 30), now), 0);
    });
  });

  group('detailFor', () {
    test('overdue shows the due date and days late', () {
      // Event Nov 20 -> return Nov 21 -> 2 days late on Nov 23.
      final booking = _booking(DateTime(2026, 11, 20));
      expect(
        DashboardDates.detailFor(DashboardSection.overdueReturns, booking, now),
        'Due Nov 21, 2026 · 2 days late',
      );
    });

    test('one day late is singular', () {
      final booking = _booking(DateTime(2026, 11, 21));
      expect(
        DashboardDates.detailFor(DashboardSection.overdueReturns, booking, now),
        endsWith('1 day late'),
      );
    });

    test('expiring soon shows when it expires', () {
      final booking = _booking(
        DateTime(2026, 12, 24),
        expiresAt: DateTime(2026, 11, 24, 9),
      );
      expect(
        DashboardDates.detailFor(DashboardSection.expiringSoon, booking, now),
        'Expires Nov 24, 2026 9:00 AM',
      );
    });
  });
}
