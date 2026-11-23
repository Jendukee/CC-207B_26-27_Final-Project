// Calendar logic in plain Dart (no widgets, no Supabase) so it can be unit
// tested:
//   * which days a booking covers (pick-up, event, return)
//   * the bookings on each day
//   * conflicts: more than one BLOCKING booking (reserved / rented out) on
//     the same item and the same day. The database exclusion constraint
//     should make this impossible; the calendar still checks, so a data
//     problem is visible instead of hidden.
//   * the item / category filter
//
// All days are compared as UTC midnight "day keys", the same form
// table_calendar uses for its day cells.
//
// OWNER: Member 3.

import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// What a day is for a booking.
enum BookingDayRole {
  /// Customer picks up the items (day before the event).
  pickup('Pick-up'),

  /// The customer's event.
  event('Event'),

  /// Customer brings the items back (day after the event).
  returnDay('Return');

  const BookingDayRole(this.label);

  /// Text shown to staff.
  final String label;
}

/// Item / category filter. When [itemId] is set it wins over [type].
class CalendarFilter {
  /// Creates a filter; the default shows everything.
  const CalendarFilter({this.type, this.itemId});

  /// Only gowns or only suits; null for both.
  final ItemType? type;

  /// Only bookings that include this item; null for any item.
  final String? itemId;

  /// True when nothing is filtered.
  bool get isEmpty => type == null && itemId == null;
}

/// Pure calendar functions.
abstract final class CalendarRules {
  /// Statuses shown on the calendar. Cancelled and expired bookings do not
  /// hold any dates, so they are left out.
  static const List<BookingStatus> shownStatuses = [
    BookingStatus.pending,
    BookingStatus.reserved,
    BookingStatus.rentedOut,
    BookingStatus.returned,
  ];

  /// The UTC-midnight key for [date]'s calendar day.
  static DateTime dayKey(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Every day from pick-up to return, inclusive.
  static List<DateTime> daysOf(CalendarBooking booking) {
    final start = dayKey(booking.booking.pickupDate);
    final end = dayKey(booking.booking.returnDate);
    return [
      for (
        var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      )
        day,
    ];
  }

  /// Pick-up, event or return for [day]; null if the booking is not on it.
  static BookingDayRole? roleOn(CalendarBooking booking, DateTime day) {
    final key = dayKey(day);
    if (key == dayKey(booking.booking.pickupDate)) return BookingDayRole.pickup;
    if (key == dayKey(booking.booking.returnDate)) {
      return BookingDayRole.returnDay;
    }
    if (key == dayKey(booking.booking.eventDate)) return BookingDayRole.event;
    return null;
  }

  /// The status to display: a pending booking past expires_at shows as
  /// expired (same rule as the bookings list).
  static BookingStatus displayStatus(CalendarBooking booking, {DateTime? now}) {
    final row = booking.booking;
    final expiresAt = row.expiresAt;
    final pastExpiry =
        row.status == BookingStatus.pending &&
        expiresAt != null &&
        expiresAt.isBefore(now ?? DateTime.now());
    return pastExpiry ? BookingStatus.expired : row.status;
  }

  /// True if [booking] passes [filter].
  static bool matches(CalendarBooking booking, CalendarFilter filter) {
    if (filter.itemId != null) {
      return booking.items.any((i) => i.id == filter.itemId);
    }
    if (filter.type != null) {
      return booking.items.any((i) => i.type == filter.type);
    }
    return true;
  }

  /// Bookings per day key. A booking appears on each of its days.
  static Map<DateTime, List<CalendarBooking>> byDay(
    List<CalendarBooking> bookings,
  ) {
    final map = <DateTime, List<CalendarBooking>>{};
    for (final booking in bookings) {
      for (final day in daysOf(booking)) {
        map.putIfAbsent(day, () => []).add(booking);
      }
    }
    return map;
  }

  /// For each day with a conflict, the ids of the bookings involved.
  /// A conflict = two or more blocking bookings holding the same item on
  /// the same day.
  static Map<DateTime, Set<String>> conflicts(List<CalendarBooking> bookings) {
    // (day, item id) -> ids of blocking bookings holding that item that day
    final holders = <(DateTime, String), Set<String>>{};
    for (final booking in bookings) {
      if (!booking.booking.status.blocksDates) continue;
      for (final day in daysOf(booking)) {
        for (final item in booking.items) {
          holders.putIfAbsent((day, item.id), () => {}).add(booking.booking.id);
        }
      }
    }

    final result = <DateTime, Set<String>>{};
    holders.forEach((key, ids) {
      if (ids.length > 1) result.putIfAbsent(key.$1, () => {}).addAll(ids);
    });
    return result;
  }

  /// First and last day to load for the month containing [focusedDay].
  /// One week of padding on each side covers the days of the neighbouring
  /// months that a month or week view can show.
  static (DateTime, DateTime) loadRange(DateTime focusedDay) {
    final first = DateTime.utc(focusedDay.year, focusedDay.month, 1);
    final last = DateTime.utc(focusedDay.year, focusedDay.month + 1, 0);
    return (
      first.subtract(const Duration(days: 7)),
      last.add(const Duration(days: 7)),
    );
  }
}
