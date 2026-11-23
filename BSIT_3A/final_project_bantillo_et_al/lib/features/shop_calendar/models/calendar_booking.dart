// A booking as the staff calendar needs it: the shared Booking row, the
// customer's name and the booked items (id, name, type, size).
//
// The shared Booking model has no customer or item fields, so this
// feature-private model wraps it instead of changing lib/shared/.
//
// OWNER: Member 3.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// A rentable item, as shown in the calendar filter and booking rows.
class CalendarItem {
  /// Creates an item.
  const CalendarItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
  });

  /// Builds an item from an `items` row (id, name, type, size).
  factory CalendarItem.fromMap(Map<String, dynamic> map) => CalendarItem(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Unknown item',
    type: ItemType.fromDb(map['type'] as String? ?? 'gown'),
    size: map['size'] as String? ?? '',
  );

  /// items.id
  final String id;

  /// items.name
  final String name;

  /// Gown or suit.
  final ItemType type;

  /// Size label.
  final String size;

  /// "Ivory Ball Gown (M)", used in the filter dropdown.
  String get label => size.isEmpty ? name : '$name ($size)';
}

/// One booking on the calendar.
class CalendarBooking {
  /// Creates it.
  const CalendarBooking({
    required this.booking,
    required this.customerName,
    this.items = const [],
  });

  /// Builds it from a `bookings` row with embedded `customer` and
  /// `booking_items(item:items(...))`.
  factory CalendarBooking.fromMap(Map<String, dynamic> map) {
    final customer = map['customer'] as Map<String, dynamic>?;
    final rows = map['booking_items'] as List? ?? const [];
    final name = (customer?['full_name'] as String? ?? '').trim();
    return CalendarBooking(
      booking: Booking.fromMap(map),
      customerName: name.isEmpty ? 'Unnamed customer' : name,
      items: [
        for (final row in rows)
          if ((row as Map<String, dynamic>)['item'] != null)
            CalendarItem.fromMap(row['item'] as Map<String, dynamic>),
      ],
    );
  }

  /// The bookings row.
  final Booking booking;

  /// profiles.full_name of the customer.
  final String customerName;

  /// Booked items.
  final List<CalendarItem> items;

  /// Item names joined, e.g. "Ivory Ball Gown, Classic Black Tuxedo".
  String get itemNames => items.map((i) => i.name).join(', ');
}
