// Staff booking management: list, details, record payments, change status.
// Tables: bookings (read/update status), booking_items, payments (insert),
// profiles (read customer contact).
//
// Changing a booking to reserved / rented_out makes its booking_items
// blocking; the database rejects it if the dates overlap another blocking
// booking (exclusion constraint). Catch that error and show a conflict
// message.
//
// OWNER: Member 3. Every method is a stub that throws UnimplementedError
// until Member 3 implements it.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// Staff-side booking operations (staff/owner RLS).
class ShopBookingsService {
  /// All bookings, optionally filtered by [status] or a search [query]
  /// (reference number or customer name).
  Future<List<Booking>> listBookings({BookingStatus? status, String? query}) =>
      throw UnimplementedError('TODO(Member 3): list bookings');

  /// One booking by [bookingId].
  Future<Booking> getBooking(String bookingId) =>
      throw UnimplementedError('TODO(Member 3): select booking');

  /// Payments recorded for [bookingId].
  Future<List<Payment>> listPayments(String bookingId) =>
      throw UnimplementedError('TODO(Member 3): list payments');

  /// Inserts [payment] and updates bookings.amount_paid.
  Future<void> recordPayment(Payment payment) =>
      throw UnimplementedError('TODO(Member 3): record payment');

  /// Changes the booking status (e.g. pending -> reserved).
  Future<void> updateStatus(String bookingId, BookingStatus status) =>
      throw UnimplementedError('TODO(Member 3): update status');
}
