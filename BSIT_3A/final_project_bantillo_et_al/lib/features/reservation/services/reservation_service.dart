// Customer reservation flow: conflict check and booking submission.
// Tables/RPCs: bookings (insert), booking_items (insert),
// get_blocked_dates (RPC), measurements (read).
//
// The database is the final guard against double booking: an exclusion
// constraint on booking_items rejects overlapping reserved/rented-out
// periods even if two staff confirm at once. Still check in the app first
// for a friendly message.
//
// OWNER: Member 2. Every method is a stub that throws UnimplementedError
// until Member 2 implements it.

import 'package:orange150_rental/shared/models/booking.dart';

/// Creates reservations for the signed-in customer.
class ReservationService {
  /// True if [itemId] is free from the day before to the day after
  /// [eventDate].
  Future<bool> isItemAvailable({
    required String itemId,
    required DateTime eventDate,
  }) =>
      throw UnimplementedError('TODO(Member 2): conflict check');

  /// The customer's saved measurements (to prefill step 2), or null.
  Future<Map<String, dynamic>?> loadSavedMeasurements() =>
      throw UnimplementedError('TODO(Member 2): read measurements');

  /// Creates a pending booking + booking_items row and returns it.
  Future<Booking> submitReservation({
    required String itemId,
    required DateTime eventDate,
    required PaymentOption paymentOption,
    required Map<String, dynamic> measurementsSnapshot,
    required String termsVersion,
  }) =>
      throw UnimplementedError('TODO(Member 2): insert booking');

  /// Loads a booking for the confirmation screen.
  Future<Booking> getBooking(String bookingId) =>
      throw UnimplementedError('TODO(Member 2): select booking');
}
