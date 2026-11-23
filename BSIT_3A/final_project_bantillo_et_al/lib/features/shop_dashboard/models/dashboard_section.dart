// The five dashboard sections and the pure date logic behind them (no
// Supabase, no widgets) so it can be unit tested.
//
// Each section knows:
//   * its title, icon and empty message
//   * the link to the filtered bookings list (/shop/bookings?...)
//   * the detail line shown for each booking (e.g. "2 days late")
//
// The bookings list filters by EVENT date, and the rental dates are fixed
// around the event (pickup = event - 1 day, return = event + 1 day), so:
//   pick-ups today  -> event date = tomorrow
//   returns today   -> event date = yesterday
//   overdue returns -> event date <= 2 days ago (return date before today)
//
// OWNER: Member 3.

import 'package:flutter/material.dart' show IconData, Icons;

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking.dart';

/// One dashboard card.
enum DashboardSection {
  /// pickup_date = today, status reserved.
  pickupsToday(
    'Pick-ups today',
    Icons.outbox_outlined,
    'Nothing scheduled today',
  ),

  /// return_date = today, status rented_out.
  returnsToday(
    'Returns today',
    Icons.assignment_return_outlined,
    'Nothing scheduled today',
  ),

  /// return_date before today, still rented_out.
  overdueReturns(
    'Overdue returns',
    Icons.warning_amber_rounded,
    'No overdue returns',
  ),

  /// Pending, expires_at within the next 24 hours.
  expiringSoon(
    'Requests expiring in 24 h',
    Icons.timer_outlined,
    'No requests expiring soon',
  ),

  /// Pending, created since the start of yesterday.
  newRequests(
    'New requests since yesterday',
    Icons.fiber_new_outlined,
    'No new requests',
  );

  const DashboardSection(this.title, this.icon, this.emptyMessage);

  /// Card heading.
  final String title;

  /// Card icon.
  final IconData icon;

  /// Shown when the section has no bookings.
  final String emptyMessage;

  /// True for sections that need attention (shown with a warning color).
  bool get isAlert => this == overdueReturns || this == expiringSoon;
}

/// Date helpers. Every function takes `now` so tests can fix the time.
abstract final class DashboardDates {
  /// Midnight at the start of [now]'s day (local time).
  static DateTime today(DateTime now) => DateTime(now.year, now.month, now.day);

  /// Start of yesterday (local time), used for "new requests".
  static DateTime startOfYesterday(DateTime now) =>
      today(now).subtract(const Duration(days: 1));

  /// Whole days between [returnDate] and today; 0 if not late.
  static int daysLate(DateTime returnDate, DateTime now) {
    final due = DateTime(returnDate.year, returnDate.month, returnDate.day);
    final days = today(now).difference(due).inDays;
    return days < 0 ? 0 : days;
  }

  /// The second line under a booking in [section], e.g.
  /// "Due Nov 21, 2026 · 2 days late" or "Expires Nov 24, 2026 9:00 AM".
  static String detailFor(
    DashboardSection section,
    Booking booking,
    DateTime now,
  ) {
    switch (section) {
      case DashboardSection.pickupsToday:
        return 'Event ${Formatters.date(booking.eventDate)}';
      case DashboardSection.returnsToday:
        return 'Due back today';
      case DashboardSection.overdueReturns:
        final late = daysLate(booking.returnDate, now);
        return 'Due ${Formatters.date(booking.returnDate)} · '
            '$late ${late == 1 ? 'day' : 'days'} late';
      case DashboardSection.expiringSoon:
        final expiresAt = booking.expiresAt;
        return expiresAt == null
            ? 'No expiry set'
            : 'Expires ${Formatters.dateTime(expiresAt)}';
      case DashboardSection.newRequests:
        final createdAt = booking.createdAt;
        return createdAt == null
            ? 'Event ${Formatters.date(booking.eventDate)}'
            : 'Requested ${Formatters.dateTime(createdAt)}';
    }
  }

  /// Link to the shop bookings list filtered for [section], e.g.
  /// /shop/bookings?status=reserved&from=2026-11-24&to=2026-11-24
  static String bookingsLink(DashboardSection section, DateTime now) {
    final day = today(now);
    String iso(int offsetDays) =>
        Formatters.isoDate(day.add(Duration(days: offsetDays)));

    final query = switch (section) {
      DashboardSection.pickupsToday => {
        'status': 'reserved',
        'from': iso(1),
        'to': iso(1),
      },
      DashboardSection.returnsToday => {
        'status': 'rented_out',
        'from': iso(-1),
        'to': iso(-1),
      },
      DashboardSection.overdueReturns => {
        'status': 'rented_out',
        'from': '2000-01-01',
        'to': iso(-2),
      },
      // The list has no "expires" filter; it shows all pending requests,
      // newest first.
      DashboardSection.expiringSoon ||
      DashboardSection.newRequests => {'status': 'pending'},
    };
    return Uri(
      path: RoutePaths.shopBookings,
      queryParameters: query,
    ).toString();
  }
}
