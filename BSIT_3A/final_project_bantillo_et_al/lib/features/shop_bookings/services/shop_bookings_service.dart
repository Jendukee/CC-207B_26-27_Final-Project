// Staff booking management: list with search/filters, booking details,
// record payments and change status.
//
// Tables read: bookings, profiles (customer name/phone), booking_items,
// items, payments (SELECT grants come from 0006_table_grants.sql). Writes go
// ONLY through the SQL functions in supabase/migrations/0002_shop_bookings.sql:
//   * record_payment(...)        payment + amount_paid + pending -> reserved
//   * update_booking_status(...) cancel / rented_out / returned
//
// Reserving makes the booking's items block their dates. If another booking
// already holds those dates, Postgres rejects it with code 23P01 and we show
// [ShopBookingsService.dateConflictMessage].
//
// OWNER: Member 3.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/shop_bookings/models/booking_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/payment_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking_filter.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// Thrown by [ShopBookingsService] with a message that is safe to show.
class ShopBookingsException implements Exception {
  /// Creates the exception.
  const ShopBookingsException(this.message);

  /// Friendly text for a snackbar or error view.
  final String message;

  @override
  String toString() => message;
}

/// Staff-side booking operations (staff/owner RLS).
class ShopBookingsService {
  /// Shown when the exclusion constraint rejects a reserve.
  static const String dateConflictMessage =
      'These dates were just taken by another booking. '
      'Contact the customer to pick new dates.';

  /// Most rows the list loads at once.
  static const int listLimit = 200;

  SupabaseClient get _db => SupabaseService.client;

  // The customer relation is named explicitly (bookings_customer_id_fkey)
  // because payments/checklists also link bookings to profiles.
  static const String _listColumns =
      '*, '
      'customer:profiles!bookings_customer_id_fkey(full_name, phone), '
      'booking_items(price, item:items(id, name, type, size, inclusions))';

  static const String _detailColumns = '$_listColumns, payments(*)';

  /// Bookings matching [filter], newest first.
  Future<List<ShopBooking>> listBookings(ShopBookingFilter filter) async {
    try {
      var request = _db.from('bookings').select(_listColumns);

      // Status. Pending and expired are refined below, because a pending
      // row past expires_at is displayed as expired.
      final status = filter.status;
      if (status == BookingStatus.pending) {
        request = request.eq('status', 'pending');
      } else if (status == BookingStatus.expired) {
        request = request.inFilter('status', ['pending', 'expired']);
      } else if (status != null) {
        request = request.eq('status', status.dbValue);
      }

      // Event date range.
      if (filter.from != null) {
        request = request.gte('event_date', Formatters.isoDate(filter.from!));
      }
      if (filter.to != null) {
        request = request.lte('event_date', Formatters.isoDate(filter.to!));
      }

      // Search: reference number OR a customer whose name matches.
      final search = _cleanSearch(filter.query);
      if (search.isNotEmpty) {
        final customerIds = await _customerIdsMatching(search);
        final conditions = [
          'reference_no.ilike.*$search*',
          if (customerIds.isNotEmpty)
            'customer_id.in.(${customerIds.join(',')})',
        ];
        request = request.or(conditions.join(','));
      }

      final rows = await request
          .order('created_at', ascending: false)
          .limit(listLimit);

      final bookings = rows.map(ShopBooking.fromMap).toList();
      if (status == null) return bookings;
      // Keep only rows whose DISPLAYED status matches the chip.
      return bookings
          .where((b) => BookingRules.effectiveStatus(b.booking) == status)
          .toList();
    } catch (error) {
      throw ShopBookingsException(friendlyError(error));
    }
  }

  /// One booking with customer, items, measurements snapshot and payments
  /// (oldest payment first).
  Future<ShopBooking> getBookingDetails(String bookingId) async {
    try {
      final row = await _db
          .from('bookings')
          .select(_detailColumns)
          .eq('id', bookingId)
          .order('created_at', referencedTable: 'payments')
          .single();
      return ShopBooking.fromMap(row);
    } catch (error) {
      throw ShopBookingsException(friendlyError(error));
    }
  }

  /// Records a payment via the record_payment SQL function. Returns the
  /// updated booking (status may now be reserved).
  Future<Booking> recordPayment({
    required String bookingId,
    required double amount,
    required PaymentKind kind,
    required PaymentMethod method,
  }) async {
    try {
      final row = await _db.rpc<Map<String, dynamic>>(
        'record_payment',
        params: {
          'p_booking_id': bookingId,
          'p_amount': amount,
          'p_kind': kind.dbValue,
          'p_method': method.dbValue,
        },
      );
      return Booking.fromMap(row);
    } catch (error) {
      throw ShopBookingsException(friendlyError(error));
    }
  }

  /// Changes the status via the update_booking_status SQL function, which
  /// only allows the transitions in BookingRules.
  Future<Booking> updateStatus(String bookingId, BookingStatus status) async {
    try {
      final row = await _db.rpc<Map<String, dynamic>>(
        'update_booking_status',
        params: {'p_booking_id': bookingId, 'p_new_status': status.dbValue},
      );
      return Booking.fromMap(row);
    } catch (error) {
      throw ShopBookingsException(friendlyError(error));
    }
  }

  /// Cancels a pending or reserved booking.
  Future<Booking> cancelBooking(String bookingId) =>
      updateStatus(bookingId, BookingStatus.cancelled);

  /// Turns any error into a message staff can understand.
  static String friendlyError(Object error) {
    debugPrint('ShopBookingsService error: $error');
    if (error is ShopBookingsException) return error.message;
    if (error is PostgrestException) {
      final (code, message) = _unwrap(error);
      // Our own RAISE EXCEPTION messages (P0001) are already friendly.
      if (code == 'P0001') return message;
      // Exclusion constraint: the dates are already blocked.
      if (code == '23P01') return dateConflictMessage;
      // .single() found no row.
      if (code == 'PGRST116') {
        return 'Booking not found. It may have been deleted.';
      }
      // 42501 is either "not staff" from our functions or a missing grant.
      if (code == '42501' || code == '403') {
        if (message.contains('permission denied')) {
          return 'The database blocked this request (missing permission). '
              'Make sure 0006_table_grants.sql and 0002_shop_bookings.sql '
              'have been run in Supabase.';
        }
        return 'Only staff and owner accounts can do this. '
            'Sign in with a staff account.';
      }
      // PostgREST does not know the function: the migration was not run.
      if (code == 'PGRST202') {
        return 'This feature is not set up in the database yet. '
            'Run 0002_shop_bookings.sql in the Supabase SQL editor.';
      }
      return 'The server could not complete this request. Please try again.';
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Returns the Postgres error code and message. Sometimes (seen on web)
  /// the client puts the raw JSON body in `message` and the HTTP status in
  /// `code`, e.g. message = '{"code":"P0001","message":"..."}', code = 400.
  /// In that case the real code and message are read from the JSON.
  static (String, String) _unwrap(PostgrestException error) {
    final raw = error.message.trim();
    if (raw.startsWith('{')) {
      try {
        final body = jsonDecode(raw) as Map<String, dynamic>;
        return (
          body['code']?.toString() ?? error.code ?? '',
          body['message']?.toString() ?? raw,
        );
      } catch (_) {
        // Not JSON after all; fall through.
      }
    }
    return (error.code ?? '', error.message);
  }

  /// Ids of customers whose name contains [search] (at most 50).
  Future<List<String>> _customerIdsMatching(String search) async {
    final rows = await _db
        .from('profiles')
        .select('id')
        .ilike('full_name', '%$search%')
        .limit(50);
    return [for (final row in rows) row['id'] as String];
  }

  /// Removes characters that have a special meaning inside a PostgREST
  /// `or=(...)` filter, so typed text cannot break the query.
  static String _cleanSearch(String text) =>
      text.replaceAll(RegExp(r'[,()*%\\"]'), ' ').trim();
}
