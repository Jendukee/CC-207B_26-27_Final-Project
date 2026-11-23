// Unit tests for the calendar logic (CalendarRules): booking days, roles,
// conflicts, the item / category filter and the load range.
// No Supabase connection needed.
// Run with: flutter test test/features/shop_calendar

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';

const _gown = CalendarItem(
  id: 'gown1',
  name: 'Ivory Ball Gown',
  type: ItemType.gown,
  size: 'M',
);
const _suit = CalendarItem(
  id: 'suit1',
  name: 'Classic Black Tuxedo',
  type: ItemType.suit,
  size: '40R',
);

/// A booking for an event on [event] holding [items].
CalendarBooking _booking(
  String id,
  DateTime event, {
  BookingStatus status = BookingStatus.reserved,
  List<CalendarItem> items = const [_gown],
  DateTime? expiresAt,
}) {
  return CalendarBooking(
    customerName: 'Ana',
    items: items,
    booking: Booking(
      id: id,
      referenceNo: 'O150-$id',
      customerId: 'c1',
      status: status,
      paymentOption: PaymentOption.full,
      totalAmount: 3500,
      amountPaid: 0,
      pickupDate: event.subtract(const Duration(days: 1)),
      eventDate: event,
      returnDate: event.add(const Duration(days: 1)),
      expiresAt: expiresAt,
    ),
  );
}

void main() {
  final event = DateTime(2026, 12, 24);

  test('a booking covers pick-up, event and return days', () {
    final days = CalendarRules.daysOf(_booking('a', event));
    expect(days, [
      DateTime.utc(2026, 12, 23),
      DateTime.utc(2026, 12, 24),
      DateTime.utc(2026, 12, 25),
    ]);
  });

  test('roleOn tells pick-up, event and return apart', () {
    final booking = _booking('a', event);
    expect(
      CalendarRules.roleOn(booking, DateTime.utc(2026, 12, 23)),
      BookingDayRole.pickup,
    );
    expect(
      CalendarRules.roleOn(booking, DateTime.utc(2026, 12, 24)),
      BookingDayRole.event,
    );
    expect(
      CalendarRules.roleOn(booking, DateTime.utc(2026, 12, 25)),
      BookingDayRole.returnDay,
    );
    expect(CalendarRules.roleOn(booking, DateTime.utc(2026, 12, 26)), isNull);
  });

  test('byDay lists a booking on each of its days', () {
    final map = CalendarRules.byDay([_booking('a', event)]);
    expect(map.keys.length, 3);
    expect(map[DateTime.utc(2026, 12, 24)]!.single.booking.id, 'a');
  });

  group('conflicts', () {
    test('two blocking bookings on the same item and day conflict', () {
      // a: Dec 23-25, b: Dec 25-27 -> overlap on Dec 25 only.
      final a = _booking('a', event);
      final b = _booking('b', DateTime(2026, 12, 26));
      final result = CalendarRules.conflicts([a, b]);
      expect(result.keys, [DateTime.utc(2026, 12, 25)]);
      expect(result[DateTime.utc(2026, 12, 25)], {'a', 'b'});
    });

    test('pending bookings do not block, so they never conflict', () {
      final a = _booking('a', event);
      final b = _booking('b', event, status: BookingStatus.pending);
      expect(CalendarRules.conflicts([a, b]), isEmpty);
    });

    test('different items on the same day do not conflict', () {
      final a = _booking('a', event);
      final b = _booking('b', event, items: const [_suit]);
      expect(CalendarRules.conflicts([a, b]), isEmpty);
    });
  });

  group('filter', () {
    final both = _booking('a', event, items: const [_gown, _suit]);
    final suitOnly = _booking('b', event, items: const [_suit]);

    test('category keeps bookings with at least one item of that type', () {
      const gowns = CalendarFilter(type: ItemType.gown);
      expect(CalendarRules.matches(both, gowns), isTrue);
      expect(CalendarRules.matches(suitOnly, gowns), isFalse);
    });

    test('item filter wins over category', () {
      const item = CalendarFilter(type: ItemType.gown, itemId: 'suit1');
      expect(CalendarRules.matches(suitOnly, item), isTrue);
    });

    test('empty filter keeps everything', () {
      expect(CalendarRules.matches(suitOnly, const CalendarFilter()), isTrue);
    });
  });

  test('pending past expires_at displays as expired', () {
    final now = DateTime(2026, 11, 23, 12);
    final late = _booking(
      'a',
      event,
      status: BookingStatus.pending,
      expiresAt: now.subtract(const Duration(minutes: 1)),
    );
    expect(CalendarRules.displayStatus(late, now: now), BookingStatus.expired);
  });

  test('loadRange pads the month by a week on each side', () {
    final (from, to) = CalendarRules.loadRange(DateTime.utc(2026, 2, 10));
    expect(from, DateTime.utc(2026, 1, 25));
    expect(to, DateTime.utc(2026, 3, 7)); // Feb 28 + 7 days
  });
}
