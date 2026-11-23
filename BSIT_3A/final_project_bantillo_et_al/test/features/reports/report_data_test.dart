// Unit tests for the reports models (MonthValue, TopItem, ReportMath).
// No Supabase connection needed.
// Run with: flutter test test/features/reports

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/reports/models/report_data.dart';
import 'package:orange150_rental/shared/models/item.dart';

void main() {
  group('parsing rows from the SQL functions', () {
    test('MonthValue reads numbers and numeric strings', () {
      final rentals = MonthValue.fromMap({
        'month': '2026-11-01',
        'rentals': 12,
      }, 'rentals');
      final revenue = MonthValue.fromMap({
        'month': '2026-10-01',
        'revenue': '15250.50',
      }, 'revenue');
      expect(rentals.month, DateTime(2026, 11, 1));
      expect(rentals.value, 12);
      expect(revenue.value, 15250.5);
    });

    test('TopItem reads a report_top_items row', () {
      final item = TopItem.fromMap({
        'item_id': 'i1',
        'name': 'Ivory Ball Gown',
        'type': 'gown',
        'size': 'M',
        'rentals': 7,
      });
      expect(item.type, ItemType.gown);
      expect(item.rentals, 7);
    });
  });

  group('ReportMath', () {
    List<MonthValue> values(List<double> numbers) => [
      for (var i = 0; i < numbers.length; i++)
        MonthValue(month: DateTime(2026, i + 1), value: numbers[i]),
    ];

    test('empty state when every month is 0', () {
      expect(ReportMath.isAllZero(values([0, 0, 0])), isTrue);
      expect(ReportMath.isAllZero(values([0, 3, 0])), isFalse);
      expect(ReportMath.isAllZero(const []), isTrue);
    });

    test('total adds every month', () {
      expect(ReportMath.total(values([1, 2, 3.5])), 6.5);
    });

    test('niceMax rounds up to a tidy axis top', () {
      expect(ReportMath.niceMax(values([7])), 10);
      expect(ReportMath.niceMax(values([23])), 25);
      expect(ReportMath.niceMax(values([4300])), 5000);
      expect(ReportMath.niceMax(values([10])), 20); // keeps headroom
      expect(ReportMath.niceMax(values([0])), 1);
    });

    test('compactPeso shortens axis labels', () {
      expect(ReportMath.compactPeso(0), '₱0');
      expect(ReportMath.compactPeso(1500), '₱1.5k');
      expect(ReportMath.compactPeso(20000), '₱20k');
      expect(ReportMath.compactPeso(2000000), '₱2M');
    });

    test('month labels', () {
      expect(ReportMath.shortMonth(DateTime(2026, 11)), 'Nov');
      expect(ReportMath.longMonth(DateTime(2026, 11)), 'November 2026');
    });
  });

  test('range selector values match the SQL p_months', () {
    expect(ReportRange.values.map((r) => r.months), [3, 6, 12]);
  });
}
