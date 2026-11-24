// Unit tests for EventDateRules (UI audit #13): which event dates are
// free and which alternatives are suggested.
// Run with: flutter test test/features/reservation

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/reservation/models/event_date_rules.dart';

void main() {
  // Another booking holds Dec 23-25 (pick-up, event, return).
  final blocked = {
    DateTime(2026, 12, 23),
    DateTime(2026, 12, 24),
    DateTime(2026, 12, 25),
  };
  final earliest = DateTime(2026, 12, 1);
  final latest = DateTime(2027, 12, 1);

  test('a date is free only if pick-up, event and return are all free', () {
    // Event Dec 22 -> return Dec 23 is blocked.
    expect(EventDateRules.isFree(DateTime(2026, 12, 22), blocked), isFalse);
    // Event Dec 26 -> pick-up Dec 25 is blocked.
    expect(EventDateRules.isFree(DateTime(2026, 12, 26), blocked), isFalse);
    // Event Dec 21 (Dec 20-22) and Dec 27 (Dec 26-28) are free.
    expect(EventDateRules.isFree(DateTime(2026, 12, 21), blocked), isTrue);
    expect(EventDateRules.isFree(DateTime(2026, 12, 27), blocked), isTrue);
  });

  test('time of day is ignored', () {
    expect(
      EventDateRules.isFree(DateTime(2026, 12, 24, 15, 30), blocked),
      isFalse,
    );
  });

  test('firstFree skips blocked dates', () {
    expect(
      EventDateRules.firstFree(DateTime(2026, 12, 22), latest, blocked),
      DateTime(2026, 12, 27),
    );
  });

  test('nearestFree suggests the closest free dates on both sides', () {
    final suggestions = EventDateRules.nearestFree(
      DateTime(2026, 12, 24),
      blocked,
      earliest: earliest,
      latest: latest,
    );
    // Distance 3: Dec 21 and Dec 27; distance 4: Dec 20 (checked before 28).
    expect(suggestions, [
      DateTime(2026, 12, 20),
      DateTime(2026, 12, 21),
      DateTime(2026, 12, 27),
    ]);
  });

  test('nearestFree never suggests a date before the earliest allowed', () {
    final suggestions = EventDateRules.nearestFree(
      DateTime(2026, 12, 24),
      blocked,
      earliest: DateTime(2026, 12, 24),
      latest: latest,
    );
    expect(
      suggestions.every((d) => !d.isBefore(DateTime(2026, 12, 24))),
      isTrue,
    );
  });
}
