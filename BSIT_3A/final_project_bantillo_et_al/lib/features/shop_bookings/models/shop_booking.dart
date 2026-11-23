// A booking as the staff screens need it: the shared Booking row plus the
// customer's name and phone, the booked items and the payment history.
// Built from one Supabase query with embedded tables (see
// ShopBookingsService).
//
// The shared Booking model has no customer or item fields, so this
// feature-private model wraps it instead of changing lib/shared/.
//
// OWNER: Member 3.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// One item line of a booking (booking_items joined with items).
class ShopBookingItem {
  /// Creates an item line.
  const ShopBookingItem({
    required this.itemId,
    required this.name,
    required this.type,
    required this.size,
    required this.price,
    this.inclusions = const [],
  });

  /// Builds a line from `booking_items(price, item:items(...))`.
  factory ShopBookingItem.fromMap(Map<String, dynamic> map) {
    final item = map['item'] as Map<String, dynamic>? ?? const {};
    return ShopBookingItem(
      itemId: item['id'] as String? ?? '',
      name: item['name'] as String? ?? 'Unknown item',
      type: ItemType.fromDb(item['type'] as String? ?? 'gown'),
      size: item['size'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      inclusions: List<String>.from(item['inclusions'] as List? ?? const []),
    );
  }

  /// items.id
  final String itemId;

  /// items.name
  final String name;

  /// Gown or suit.
  final ItemType type;

  /// Size label.
  final String size;

  /// Price charged for this item in this booking (booking_items.price).
  final double price;

  /// What comes with the item (veil, gloves, ...).
  final List<String> inclusions;
}

/// A booking with its customer, items and payments.
class ShopBooking {
  /// Creates a staff booking.
  const ShopBooking({
    required this.booking,
    required this.customerName,
    this.customerPhone,
    this.items = const [],
    this.payments = const [],
  });

  /// Builds it from a `bookings` row with embedded `customer`,
  /// `booking_items` and (on the details query) `payments`.
  factory ShopBooking.fromMap(Map<String, dynamic> map) {
    final customer = map['customer'] as Map<String, dynamic>?;
    final itemRows = map['booking_items'] as List? ?? const [];
    final paymentRows = map['payments'] as List? ?? const [];

    final name = (customer?['full_name'] as String? ?? '').trim();
    return ShopBooking(
      booking: Booking.fromMap(map),
      customerName: name.isEmpty ? 'Unnamed customer' : name,
      customerPhone: customer?['phone'] as String?,
      items: [
        for (final row in itemRows)
          ShopBookingItem.fromMap(row as Map<String, dynamic>),
      ],
      payments: [
        for (final row in paymentRows)
          Payment.fromMap(row as Map<String, dynamic>),
      ],
    );
  }

  /// The bookings row.
  final Booking booking;

  /// profiles.full_name of the customer.
  final String customerName;

  /// profiles.phone of the customer.
  final String? customerPhone;

  /// Booked items.
  final List<ShopBookingItem> items;

  /// Payments, oldest first. Empty on the list query.
  final List<Payment> payments;

  /// Item names joined, e.g. "Ivory Ball Gown, Classic Black Tuxedo".
  String get itemNames => items.map((i) => i.name).join(', ');
}
