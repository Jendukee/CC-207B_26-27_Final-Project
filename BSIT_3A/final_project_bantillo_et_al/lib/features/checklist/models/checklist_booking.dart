// The booking data the checklist screens need: the shared Booking row,
// the customer's name and the booked items with their inclusions.
//
// The shared Booking model has no customer or item fields, so this
// feature-private model wraps it instead of changing lib/shared/.
//
// OWNER: Member 3.

import 'package:orange150_rental/shared/models/booking.dart';

/// One booked item and what comes with it.
class ChecklistItem {
  /// Creates an item.
  const ChecklistItem({
    required this.itemId,
    required this.name,
    required this.size,
    this.inclusions = const [],
  });

  /// Builds an item from `booking_items(item:items(id, name, size, inclusions))`.
  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    final item = map['item'] as Map<String, dynamic>? ?? const {};
    return ChecklistItem(
      itemId: item['id'] as String? ?? '',
      name: item['name'] as String? ?? 'Unknown item',
      size: item['size'] as String? ?? '',
      inclusions: List<String>.from(item['inclusions'] as List? ?? const []),
    );
  }

  /// items.id
  final String itemId;

  /// items.name, e.g. "Ivory Ball Gown".
  final String name;

  /// Size label.
  final String size;

  /// items.inclusions, e.g. ["Petticoat", "Gloves"].
  final List<String> inclusions;
}

/// A booking with its customer name and items.
class ChecklistBooking {
  /// Creates it.
  const ChecklistBooking({
    required this.booking,
    required this.customerName,
    this.items = const [],
  });

  /// Builds it from a `bookings` row with embedded `customer` and
  /// `booking_items`.
  factory ChecklistBooking.fromMap(Map<String, dynamic> map) {
    final customer = map['customer'] as Map<String, dynamic>?;
    final rows = map['booking_items'] as List? ?? const [];
    final name = (customer?['full_name'] as String? ?? '').trim();
    return ChecklistBooking(
      booking: Booking.fromMap(map),
      customerName: name.isEmpty ? 'Unnamed customer' : name,
      items: [
        for (final row in rows)
          ChecklistItem.fromMap(row as Map<String, dynamic>),
      ],
    );
  }

  /// The bookings row (status, amounts, dates).
  final Booking booking;

  /// profiles.full_name of the customer.
  final String customerName;

  /// Booked items.
  final List<ChecklistItem> items;
}
