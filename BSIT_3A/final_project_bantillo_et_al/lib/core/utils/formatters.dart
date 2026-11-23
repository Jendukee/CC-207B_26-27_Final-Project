// Shared display formatters: peso currency and dates.
// Use these everywhere so amounts and dates look the same on every screen.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:intl/intl.dart';

/// Formatting helpers for money and dates.
abstract final class Formatters {
  static final NumberFormat _peso =
      NumberFormat.currency(locale: 'en', symbol: '₱', decimalDigits: 2);
  static final DateFormat _date = DateFormat('MMM d, y');
  static final DateFormat _dateTime = DateFormat('MMM d, y h:mm a');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  /// 1500 -> "₱1,500.00"
  static String peso(num amount) => _peso.format(amount);

  /// "Dec 24, 2026"
  static String date(DateTime date) => _date.format(date);

  /// "Dec 24, 2026 3:30 PM"
  static String dateTime(DateTime dateTime) =>
      _dateTime.format(dateTime.toLocal());

  /// "Dec 23, 2026 - Dec 25, 2026"
  static String dateRange(DateTime start, DateTime end) =>
      '${date(start)} - ${date(end)}';

  /// "2026-12-24", the format Postgres `date` columns expect.
  static String isoDate(DateTime date) => _iso.format(date);
}
