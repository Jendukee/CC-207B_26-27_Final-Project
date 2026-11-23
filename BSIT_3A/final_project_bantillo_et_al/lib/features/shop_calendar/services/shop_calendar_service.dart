// Read-only queries for the staff calendar.
// Tables: bookings (+ customer name from profiles, + booking_items with
// items) and items (for the filter). SELECT grants come from
// 0006_table_grants.sql; staff see every booking through the RLS policy
// in 0001. No new SQL.
//
// A booking overlaps a range when it starts (pick-up) on or before the
// range end AND ends (return) on or after the range start.
//
// The item / category filter is applied in Dart (CalendarRules.matches):
// a month has few bookings, and this keeps the query simple.
//
// OWNER: Member 3.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';

/// Thrown by [ShopCalendarService] with a message that is safe to show.
class CalendarException implements Exception {
  /// Creates the exception.
  const CalendarException(this.message);

  /// Friendly text for the error view.
  final String message;

  @override
  String toString() => message;
}

/// Calendar queries (staff/owner RLS).
class ShopCalendarService {
  /// Most bookings loaded for one month.
  static const int rangeLimit = 500;

  SupabaseClient get _db => SupabaseService.client;

  /// Bookings whose pick-up..return period overlaps [from]..[to]
  /// (cancelled and expired ones are left out).
  Future<List<CalendarBooking>> bookingsBetween(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final rows = await _db
          .from('bookings')
          .select(
            '*, '
            'customer:profiles!bookings_customer_id_fkey(full_name), '
            'booking_items(item:items(id, name, type, size))',
          )
          .inFilter('status', [
            for (final s in CalendarRules.shownStatuses) s.dbValue,
          ])
          .lte('pickup_date', Formatters.isoDate(to))
          .gte('return_date', Formatters.isoDate(from))
          .order('pickup_date')
          .limit(rangeLimit);
      return rows.map(CalendarBooking.fromMap).toList();
    } catch (error) {
      throw CalendarException(friendlyError(error));
    }
  }

  /// Every item, for the item filter (name order).
  Future<List<CalendarItem>> listItems() async {
    try {
      final rows = await _db
          .from('items')
          .select('id, name, type, size')
          .order('name');
      return rows.map(CalendarItem.fromMap).toList();
    } catch (error) {
      throw CalendarException(friendlyError(error));
    }
  }

  /// Turns any error into a message staff can understand.
  static String friendlyError(Object error) {
    debugPrint('ShopCalendarService error: $error');
    if (error is CalendarException) return error.message;
    if (error is PostgrestException) {
      final (code, message) = _unwrap(error);
      if (code == '42501' || code == '403') {
        if (message.contains('permission denied')) {
          return 'The database blocked this request (missing permission). '
              'Make sure 0006_table_grants.sql has been run in Supabase.';
        }
        return 'Only staff and owner accounts can see the calendar.';
      }
      return 'Could not load the calendar. Please try again.';
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Could not load the calendar. Please try again.';
  }

  /// Returns the Postgres error code and message. Sometimes (seen on web)
  /// the client puts the raw JSON body in `message` and the HTTP status in
  /// `code`; then the real values are read from the JSON.
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
}
