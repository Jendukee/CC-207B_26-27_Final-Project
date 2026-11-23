// Read-only queries for the staff dashboard cards.
// Table: bookings (+ customer name from profiles). SELECT grants come from
// 0006_table_grants.sql; staff see every booking through the RLS policy
// in 0001.
//
//   pick-ups today   pickup_date = today,     status reserved
//   returns today    return_date = today,     status rented_out
//   overdue returns  return_date < today,     status rented_out
//   expiring soon    status pending, expires_at within the next 24 hours
//   new requests     status pending, created since the start of yesterday
//                    (requests already past expires_at are left out)
//
// "Today" is the device's local date.
//
// OWNER: Member 3.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';

/// Thrown by [ShopDashboardService] with a message that is safe to show.
class DashboardException implements Exception {
  /// Creates the exception.
  const DashboardException(this.message);

  /// Friendly text for the error view.
  final String message;

  @override
  String toString() => message;
}

/// Dashboard queries (staff/owner RLS).
class ShopDashboardService {
  /// Most rows loaded per section.
  static const int sectionLimit = 100;

  SupabaseClient get _db => SupabaseService.client;

  static const String _columns =
      '*, customer:profiles!bookings_customer_id_fkey(full_name)';

  /// Bookings for one dashboard [section]. [now] can be fixed for tests.
  Future<List<DashboardBooking>> load(
    DashboardSection section, {
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    final today = Formatters.isoDate(DashboardDates.today(time));
    try {
      final base = _db.from('bookings').select(_columns);
      final List<Map<String, dynamic>> rows;

      switch (section) {
        case DashboardSection.pickupsToday:
          rows = await base
              .eq('status', 'reserved')
              .eq('pickup_date', today)
              .order('created_at')
              .limit(sectionLimit);
        case DashboardSection.returnsToday:
          rows = await base
              .eq('status', 'rented_out')
              .eq('return_date', today)
              .order('created_at')
              .limit(sectionLimit);
        case DashboardSection.overdueReturns:
          rows = await base
              .eq('status', 'rented_out')
              .lt('return_date', today)
              .order('return_date') // most overdue first
              .limit(sectionLimit);
        case DashboardSection.expiringSoon:
          rows = await base
              .eq('status', 'pending')
              .gt('expires_at', time.toUtc().toIso8601String())
              .lte(
                'expires_at',
                time.add(const Duration(hours: 24)).toUtc().toIso8601String(),
              )
              .order('expires_at') // soonest first
              .limit(sectionLimit);
        case DashboardSection.newRequests:
          rows = await base
              .eq('status', 'pending')
              .gte(
                'created_at',
                DashboardDates.startOfYesterday(time).toUtc().toIso8601String(),
              )
              .order('created_at', ascending: false) // newest first
              .limit(sectionLimit);
      }

      final bookings = rows.map(DashboardBooking.fromMap).toList();
      if (section != DashboardSection.newRequests) return bookings;
      // Leave out requests that already expired (shown as Expired elsewhere).
      return bookings.where((b) {
        final expiresAt = b.booking.expiresAt;
        return expiresAt == null || expiresAt.isAfter(time);
      }).toList();
    } catch (error) {
      throw DashboardException(friendlyError(error));
    }
  }

  /// Turns any error into a message staff can understand.
  static String friendlyError(Object error) {
    debugPrint('ShopDashboardService error: $error');
    if (error is DashboardException) return error.message;
    if (error is PostgrestException) {
      final (code, message) = _unwrap(error);
      if (code == '42501' || code == '403') {
        if (message.contains('permission denied')) {
          return 'The database blocked this request (missing permission). '
              'Make sure 0006_table_grants.sql has been run in Supabase.';
        }
        return 'Only staff and owner accounts can see the dashboard.';
      }
      return 'Could not load this section. Please try again.';
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Could not load this section. Please try again.';
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
