// A fl_chart bar chart with one bar per month. Used for both "Rentals per
// month" and "Revenue per month"; the caller passes how to format values
// (a count, or pesos via Formatters.peso).
//
// Tapping a bar shows a tooltip like "November 2026: ₱12,500.00". The
// whole chart also has a screen-reader summary, since the bars alone
// cannot be read out.
//
// OWNER: Member 3.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:orange150_rental/features/reports/models/report_data.dart';

/// Bar chart of [values] by month.
class MonthBarChart extends StatelessWidget {
  /// Creates the chart.
  const MonthBarChart({
    super.key,
    required this.values,
    required this.color,
    required this.formatValue,
    required this.formatAxis,
    this.height = 220,
  });

  /// One value per month, oldest first.
  final List<MonthValue> values;

  /// Bar color.
  final Color color;

  /// Full value text for tooltips, e.g. "12 rentals" or "₱1,500.00".
  final String Function(double value) formatValue;

  /// Short value text for the left axis, e.g. "10" or "₱1.5k".
  final String Function(double value) formatAxis;

  /// Chart height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = ReportMath.niceMax(values);
    final labelStyle = theme.textTheme.bodySmall;
    // With 12 months on a phone, label every other month so they fit.
    final labelEvery = values.length > 6 ? 2 : 1;

    final summary = values
        .map((v) => '${ReportMath.longMonth(v.month)}: ${formatValue(v.value)}')
        .join(', ');

    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i].value,
                      color: color,
                      width: values.length > 6 ? 12 : 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(formatAxis(value), style: labelStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= values.length ||
                        index % labelEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        ReportMath.shortMonth(values[index].month),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = values[group.x];
                  return BarTooltipItem(
                    '${ReportMath.longMonth(item.month)}\n'
                    '${formatValue(item.value)}',
                    TextStyle(color: theme.colorScheme.onInverseSurface),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
