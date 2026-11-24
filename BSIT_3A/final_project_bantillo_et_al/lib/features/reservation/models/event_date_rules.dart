// Which event dates a customer may pick (UI audit #13), in plain Dart so it
// can be unit tested.
//
// An event date is FREE when none of its three rental days is blocked:
//   pick-up (event - 1), the event itself, and return (event + 1).
// Blocked days come from the get_blocked_dates RPC (reserved and rented-out
// bookings only).
//
// OWNER: Member 2.

/// Pure helpers for choosing an event date.
abstract final class EventDateRules {
  /// Earliest event date a customer can choose: 2 days from today, so the
  /// pick-up (day before) is tomorrow or later and the 48-hour payment
  /// deadline ends before pick-up day (create_reservation, 0009).
  static DateTime earliestEventDate([DateTime? now]) {
    final base = now ?? DateTime.now();
    return DateTime(base.year, base.month, base.day + 2);
  }

  /// [date] without the time, so days compare correctly.
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// True when pick-up, event and return days are all free.
  static bool isFree(DateTime eventDate, Set<DateTime> blockedDays) {
    final event = day(eventDate);
    for (final offset in const [-1, 0, 1]) {
      if (blockedDays.contains(event.add(Duration(days: offset)))) {
        return false;
      }
    }
    return true;
  }

  /// The first free event date from [earliest] up to [latest], or null.
  static DateTime? firstFree(
    DateTime earliest,
    DateTime latest,
    Set<DateTime> blockedDays,
  ) {
    for (
      var date = day(earliest);
      !date.isAfter(latest);
      date = date.add(const Duration(days: 1))
    ) {
      if (isFree(date, blockedDays)) return date;
    }
    return null;
  }

  /// Up to [count] free event dates closest to [wanted] (before or after,
  /// but never before [earliest] or after [latest]), sorted by date. Shown
  /// as suggestions when the wanted date is taken.
  static List<DateTime> nearestFree(
    DateTime wanted,
    Set<DateTime> blockedDays, {
    required DateTime earliest,
    required DateTime latest,
    int count = 3,
    int searchDays = 60,
  }) {
    final center = day(wanted);
    final found = <DateTime>[];
    for (var distance = 1; distance <= searchDays; distance++) {
      for (final candidate in [
        center.subtract(Duration(days: distance)),
        center.add(Duration(days: distance)),
      ]) {
        final inRange =
            !candidate.isBefore(day(earliest)) && !candidate.isAfter(latest);
        if (inRange && isFree(candidate, blockedDays)) found.add(candidate);
        if (found.length == count) return found..sort();
      }
    }
    return found..sort();
  }
}
