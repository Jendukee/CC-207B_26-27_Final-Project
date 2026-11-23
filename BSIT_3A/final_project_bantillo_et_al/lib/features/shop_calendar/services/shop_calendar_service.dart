// Bookings for the staff calendar view.
// Tables: bookings, booking_items (read; staff RLS).
//
// OWNER: Member 3. Every method is a stub that throws UnimplementedError
// until Member 3 implements it.

import 'package:orange150_rental/shared/models/booking.dart';

/// Read-only calendar queries.
class ShopCalendarService {
  /// Bookings whose pickup..return period overlaps [from]..[to].
  Future<List<Booking>> bookingsBetween(DateTime from, DateTime to) =>
      throw UnimplementedError('TODO(Member 3): bookings in range');
}
