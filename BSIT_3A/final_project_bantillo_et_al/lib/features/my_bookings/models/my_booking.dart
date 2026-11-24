// A booking plus the items on it, as the customer sees it.
//
// OWNER: Member 2.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

class MyBooking {
  const MyBooking({required this.booking, required this.items});

  /// Builds from a `bookings` row selected with
  /// `*, booking_items(items(*))`.
  factory MyBooking.fromMap(Map<String, dynamic> map) {
    final links = (map['booking_items'] as List? ?? const []);
    final items = <Item>[];
    for (final link in links) {
      final item = (link as Map<String, dynamic>)['items'];
      if (item is Map<String, dynamic>) items.add(Item.fromMap(item));
    }
    return MyBooking(booking: Booking.fromMap(map), items: items);
  }

  final Booking booking;
  final List<Item> items;

  /// Item names for list display, e.g. "Ivory Ball Gown, Barong".
  String get itemNames =>
      items.isEmpty ? 'Booking ${booking.referenceNo}' : items.map((e) => e.name).join(', ');
}