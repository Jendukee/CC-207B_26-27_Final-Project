// The signed-in customer's own bookings: list, details and cancel.
// Tables/RPCs: bookings, booking_items, payments (read, own rows only via
// RLS), cancel_my_booking (RPC).
//
// OWNER: Member 2. Every method is a stub that throws UnimplementedError
// until Member 2 implements it.

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// Reads and cancels the current customer's bookings.
class MyBookingsService {
  /// All bookings of the signed-in customer, newest first.
  Future<List<Booking>> listMyBookings() =>
      throw UnimplementedError('TODO(Member 2): list own bookings');

  /// One booking by [bookingId].
  Future<Booking> getBooking(String bookingId) =>
      throw UnimplementedError('TODO(Member 2): select own booking');

  /// Payments recorded for [bookingId].
  Future<List<Payment>> listPayments(String bookingId) =>
      throw UnimplementedError('TODO(Member 2): list own payments');

  /// Cancels a pending or reserved booking (RPC cancel_my_booking).
  Future<void> cancelBooking(String bookingId) =>
      throw UnimplementedError('TODO(Member 2): call cancel_my_booking');
}
