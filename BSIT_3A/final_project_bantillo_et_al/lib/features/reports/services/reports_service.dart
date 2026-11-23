// Aggregated numbers for the Reports screen (fl_chart).
// Tables: bookings, booking_items, payments, items (read; staff RLS).
//
// OWNER: Member 3. Every method is a stub that throws UnimplementedError
// until Member 3 implements it.

import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Read-only report queries.
class ReportsService {
  /// Sum of payments per month (1-12) for [year], in pesos.
  Future<Map<int, double>> revenueByMonth(int year) =>
      throw UnimplementedError('TODO(Member 3): revenue by month');

  /// Number of bookings per status created between [from] and [to].
  Future<Map<BookingStatus, int>> bookingCountsByStatus({
    required DateTime from,
    required DateTime to,
  }) =>
      throw UnimplementedError('TODO(Member 3): bookings by status');

  /// Items rented most often, highest first.
  Future<List<Item>> mostRentedItems({int limit = 5}) =>
      throw UnimplementedError('TODO(Member 3): most rented items');
}
