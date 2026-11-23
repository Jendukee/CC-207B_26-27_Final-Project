// Numbers and lists for the staff dashboard cards.
// Tables: bookings, booking_items, items (read; staff RLS).
//
// OWNER: Member 3. Every method is a stub that throws UnimplementedError
// until Member 3 implements it.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Read-only queries for the dashboard.
class ShopDashboardService {
  /// Bookings with pickup_date = today.
  Future<List<Booking>> todaysPickups() =>
      throw UnimplementedError('TODO(Member 3): pickups today');

  /// Bookings with return_date = today.
  Future<List<Booking>> todaysReturns() =>
      throw UnimplementedError('TODO(Member 3): returns today');

  /// Rented-out bookings whose return_date has passed.
  Future<List<Booking>> overdueReturns() =>
      throw UnimplementedError('TODO(Member 3): overdue returns');

  /// Pending bookings awaiting payment/confirmation.
  Future<List<Booking>> pendingBookings() =>
      throw UnimplementedError('TODO(Member 3): pending bookings');

  /// Items currently in cleaning/repair.
  Future<List<Item>> itemsInCleaningRepair() =>
      throw UnimplementedError('TODO(Member 3): items in cleaning/repair');
}
