// The signed-in customer's own bookings: list, details and cancel.
// Tables/RPCs: bookings, booking_items, payments (read, own rows only via
// RLS), cancel_my_booking (RPC).
//
// OWNER: Member 2.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// Reads and cancels the current customer's bookings.
class MyBookingsService {
  MyBookingsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bookingSelect = '*, booking_items(items(*))';

  /// All bookings of the signed-in customer, newest first.
  Future<List<MyBooking>> listMyBookings() async {
    final rows = await _client
        .from('bookings')
        .select(_bookingSelect)
        .order('created_at', ascending: false);
    return rows.map<MyBooking>(MyBooking.fromMap).toList();
  }

  /// One booking by [bookingId].
  Future<MyBooking> getBooking(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select(_bookingSelect)
        .eq('id', bookingId)
        .single();
    return MyBooking.fromMap(row);
  }

  /// Payments recorded for [bookingId].
  Future<List<Payment>> listPayments(String bookingId) async {
    final rows = await _client
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true);
    return rows.map<Payment>(Payment.fromMap).toList();
  }

  /// Cancels a pending or reserved booking (RPC cancel_my_booking).
  Future<void> cancelBooking(String bookingId) async {
    await _client.rpc(
      'cancel_my_booking',
      params: {'p_booking_id': bookingId}, // ASSUMED: parameter name
    );
  }
}