// Report data and the small pure helpers the charts use (no widgets, no
// Supabase) so they can be unit tested.
//
// Rows come from the SQL functions in supabase/migrations/0004_reports.sql.
//
// OWNER: Member 3.

import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'package:orange150_rental/shared/models/item.dart';

/// How many months the report covers (the month range selector).
enum ReportRange {
  /// Last 3 months, including this one.
  months3(3, '3 months'),

  /// Last 6 months (the default).
  months6(6, '6 months'),

  /// Last 12 months.
  months12(12, '12 months');

  const ReportRange(this.months, this.label);

  /// Passed to the SQL functions as p_months.
  final int months;

  /// Text on the selector.
  final String label;
}

/// One month and a number (rentals or pesos).
class MonthValue {
  /// Creates it.
  const MonthValue({required this.month, required this.value});

  /// Builds it from a row like {"month": "2026-11-01", "rentals": 12};
  /// [valueKey] is the name of the number column ("rentals" or "revenue").
  factory MonthValue.fromMap(Map<String, dynamic> map, String valueKey) {
    return MonthValue(
      month: DateTime.parse(map['month'] as String),
      // numeric can arrive as a number or a string; handle both.
      value: num.tryParse('${map[valueKey] ?? 0}')?.toDouble() ?? 0,
    );
  }

  /// First day of the month.
  final DateTime month;

  /// Rentals (whole number) or revenue in pesos.
  final double value;
}

/// One row of the most-rented ranking.
class TopItem {
  /// Creates it.
  const TopItem({
    required this.itemId,
    required this.name,
    required this.type,
    required this.size,
    required this.rentals,
  });

  /// Builds it from a report_top_items row.
  factory TopItem.fromMap(Map<String, dynamic> map) {
    return TopItem(
      itemId: map['item_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown item',
      type: ItemType.fromDb(map['type'] as String? ?? 'gown'),
      size: map['size'] as String? ?? '',
      rentals: (map['rentals'] as num? ?? 0).toInt(),
    );
  }

  /// items.id
  final String itemId;

  /// items.name
  final String name;

  /// Gown or suit.
  final ItemType type;

  /// Size label.
  final String size;

  /// Times rented in the range.
  final int rentals;
}

/// Pure helpers for the charts.
abstract final class ReportMath {
  static final DateFormat _shortMonth = DateFormat('MMM');
  static final DateFormat _longMonth = DateFormat('MMMM y');

  /// "Nov" (axis label).
  static String shortMonth(DateTime month) => _shortMonth.format(month);

  /// "November 2026" (tooltips, screen readers).
  static String longMonth(DateTime month) => _longMonth.format(month);

  /// True when every value is 0 (or there are none): show the empty state.
  static bool isAllZero(List<MonthValue> values) =>
      values.every((v) => v.value == 0);

  /// Sum of all values.
  static double total(List<MonthValue> values) =>
      values.fold(0, (sum, v) => sum + v.value);

  /// A round top for the Y axis, a little above the highest bar, so the
  /// tallest bar does not touch the top. e.g. 7 -> 10, 23 -> 25,
  /// 4300 -> 5000.
  static double niceMax(List<MonthValue> values) {
    final highest = values.fold<double>(0, (m, v) => math.max(m, v.value));
    if (highest <= 0) return 1;
    final magnitude = math
        .pow(10, (math.log(highest) / math.ln10).floor())
        .toDouble();
    for (final step in [1, 2, 2.5, 5, 10]) {
      final candidate = step * magnitude;
      if (candidate >= highest * 1.05) return candidate;
    }
    return 10 * magnitude;
  }

  /// Shorter peso text for axis labels: 1500 -> "₱1.5k", 2000000 -> "₱2M".
  static String compactPeso(double amount) {
    if (amount >= 1000000) return '₱${_trim(amount / 1000000)}M';
    if (amount >= 1000) return '₱${_trim(amount / 1000)}k';
    return '₱${_trim(amount)}';
  }

  /// 1.0 -> "1", 1.5 -> "1.5".
  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
