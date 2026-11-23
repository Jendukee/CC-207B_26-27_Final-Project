// A booking row for the dashboard: the shared Booking plus the customer's
// name (the shared model has no customer fields, so this feature-private
// model wraps it instead of changing lib/shared/).
//
// OWNER: Member 3.

import 'package:orange150_rental/shared/models/booking.dart';

/// One booking shown under a dashboard card.
class DashboardBooking {
  /// Creates it.
  const DashboardBooking({required this.booking, required this.customerName});

  /// Builds it from a `bookings` row with an embedded `customer`.
  factory DashboardBooking.fromMap(Map<String, dynamic> map) {
    final customer = map['customer'] as Map<String, dynamic>?;
    final name = (customer?['full_name'] as String? ?? '').trim();
    return DashboardBooking(
      booking: Booking.fromMap(map),
      customerName: name.isEmpty ? 'Unnamed customer' : name,
    );
  }

  /// The bookings row.
  final Booking booking;

  /// profiles.full_name of the customer.
  final String customerName;
}
