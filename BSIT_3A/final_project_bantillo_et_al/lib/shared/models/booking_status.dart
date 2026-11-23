// Booking lifecycle shared by customer and staff features.
//
//   pending  -> reserved -> rentedOut -> returned
//      |           |
//      v           v
//   expired    cancelled
//
// Only `reserved` and `rentedOut` block an item's dates (enforced in the
// database by booking_items.is_blocking + an exclusion constraint).
//
// OWNER: team lead. Change only via a reviewed PR.

/// bookings.status
enum BookingStatus {
  /// Submitted by the customer, waiting for payment / staff confirmation.
  pending('pending', 'Pending'),

  /// Confirmed by staff. Dates are blocked.
  reserved('reserved', 'Reserved'),

  /// Picked up by the customer. Dates are blocked.
  rentedOut('rented_out', 'Rented Out'),

  /// Returned and checked.
  returned('returned', 'Returned'),

  /// Cancelled by the customer or staff.
  cancelled('cancelled', 'Cancelled'),

  /// Pending booking that was not paid before expires_at.
  expired('expired', 'Expired');

  const BookingStatus(this.dbValue, this.label);

  /// Value stored in the database (snake_case).
  final String dbValue;

  /// Human-readable label. Always show this next to the status color.
  final String label;

  /// Parses the database value. Unknown values become [pending].
  static BookingStatus fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => pending);

  /// True if this status blocks the item's dates on the calendar.
  bool get blocksDates =>
      this == BookingStatus.reserved || this == BookingStatus.rentedOut;
}
