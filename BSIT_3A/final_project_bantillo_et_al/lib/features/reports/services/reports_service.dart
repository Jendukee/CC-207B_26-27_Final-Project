// Report numbers for the Reports screen. Calls the read-only, staff-only
// SQL functions in supabase/migrations/0004_reports.sql:
//   report_rentals_per_month(p_months)
//   report_top_items(p_months, p_limit)
//   report_revenue_per_month(p_months)
//
// OWNER: Member 3.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/features/reports/models/report_data.dart';

/// Thrown by [ReportsService] with a message that is safe to show.
class ReportsException implements Exception {
  /// Creates the exception.
  const ReportsException(this.message);

  /// Friendly text for the error view.
  final String message;

  @override
  String toString() => message;
}

/// Read-only report queries (staff/owner only).
class ReportsService {
  SupabaseClient get _db => SupabaseService.client;

  /// Rentals (rented out or returned bookings) per pick-up month, oldest
  /// first. Every month in the range is included, 0 when empty.
  Future<List<MonthValue>> rentalsPerMonth(ReportRange range) async {
    final rows = await _call('report_rentals_per_month', {
      'p_months': range.months,
    });
    return [for (final row in rows) MonthValue.fromMap(row, 'rentals')];
  }

  /// The [limit] most-rented items in the range, highest first.
  Future<List<TopItem>> topItems(ReportRange range, {int limit = 5}) async {
    final rows = await _call('report_top_items', {
      'p_months': range.months,
      'p_limit': limit,
    });
    return [for (final row in rows) TopItem.fromMap(row)];
  }

  /// Payments received per month in pesos, oldest first.
  Future<List<MonthValue>> revenuePerMonth(ReportRange range) async {
    final rows = await _call('report_revenue_per_month', {
      'p_months': range.months,
    });
    return [for (final row in rows) MonthValue.fromMap(row, 'revenue')];
  }

  /// Calls a set-returning SQL function and returns its rows.
  Future<List<Map<String, dynamic>>> _call(
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await _db.rpc<List<dynamic>>(function, params: params);
      return [for (final row in result) row as Map<String, dynamic>];
    } catch (error) {
      throw ReportsException(friendlyError(error));
    }
  }

  /// Turns any error into a message staff can understand.
  static String friendlyError(Object error) {
    debugPrint('ReportsService error: $error');
    if (error is ReportsException) return error.message;
    if (error is PostgrestException) {
      final (code, message) = _unwrap(error);
      if (code == '42501' || code == '403') {
        if (message.contains('permission denied')) {
          return 'The database blocked this request (missing permission). '
              'Make sure 0004_reports.sql has been run in Supabase.';
        }
        return 'Only staff and owner accounts can see reports.';
      }
      if (code == 'PGRST202') {
        return 'Reports are not set up in the database yet. '
            'Run 0004_reports.sql in the Supabase SQL editor.';
      }
      if (code == 'P0001') return message;
      return 'Could not load this report. Please try again.';
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Could not load this report. Please try again.';
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
