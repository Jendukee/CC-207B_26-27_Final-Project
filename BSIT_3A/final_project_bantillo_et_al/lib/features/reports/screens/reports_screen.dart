// Reports (staff/owner), opened from More -> Reports (/shop/reports):
//   * Rentals per month: fl_chart bar chart
//   * Most-rented items: top 5 ranked list
//   * Revenue per month: fl_chart bar chart in pesos (Formatters.peso)
// A month range selector (3 / 6 / 12 months, default 6) reloads all three.
// Each report has its own loading, empty ("No rentals yet") and error
// (Retry) state. Pull to refresh. Wide screens (>= 900 px): the two charts
// sit side by side.
//
// Shop-side redesign (Phase 2): grey page with white SectionCards; the range
// selector (a SegmentedButton) is in its own "Time range" card at the top,
// and each chart card shows its title and total first (H1, H4, H8).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/reports/models/report_data.dart';
import 'package:orange150_rental/features/reports/services/reports_service.dart';
import 'package:orange150_rental/features/reports/widgets/month_bar_chart.dart';
import 'package:orange150_rental/features/reports/widgets/report_card.dart';
import 'package:orange150_rental/features/reports/widgets/top_items_list.dart';

/// The "Reports" screen.
class ReportsScreen extends StatefulWidget {
  /// Creates the screen.
  const ReportsScreen({super.key});

  /// Content width from which the two charts sit side by side.
  static const double twoColumnBreakpoint = 900;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _service = ReportsService();

  ReportRange _range = ReportRange.months6;

  late Future<List<MonthValue>> _rentals;
  late Future<List<TopItem>> _topItems;
  late Future<List<MonthValue>> _revenue;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Starts all three reports for [_range] (no setState: used by initState).
  void _loadAll() {
    _rentals = _service.rentalsPerMonth(_range);
    _topItems = _service.topItems(_range);
    _revenue = _service.revenuePerMonth(_range);
  }

  /// New range from the selector.
  void _setRange(ReportRange range) {
    setState(() {
      _range = range;
      _loadAll();
    });
  }

  /// Pull to refresh: reload all and wait (errors show inside each card).
  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait<Object?>([
      _rentals.then((v) => v, onError: (_) => null),
      _topItems.then((v) => v, onError: (_) => null),
      _revenue.then((v) => v, onError: (_) => null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        // Staff header: dark maroon, as on the Dashboard.
        backgroundColor: AppColors.maroonDeep,
        showLogo: false, // no hanger mark on staff headers
        title: 'Reports',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= ReportsScreen.twoColumnBreakpoint;
            final rentals = _rentalsCard();
            final revenue = _revenueCard();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _rangeSelector(),
                const SizedBox(height: 12),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: rentals),
                      const SizedBox(width: 12),
                      Expanded(child: revenue),
                    ],
                  )
                else ...[
                  rentals,
                  revenue,
                ],
                _topItemsCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 3 / 6 / 12 months.
  Widget _rangeSelector() {
    return SectionCard(
      title: 'Time range',
      icon: Icons.date_range,
      margin: EdgeInsets.zero,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Show the last', style: Theme.of(context).textTheme.bodyMedium),
          SegmentedButton<ReportRange>(
            showSelectedIcon: false,
            segments: [
              for (final range in ReportRange.values)
                ButtonSegment(value: range, label: Text(range.label)),
            ],
            selected: {_range},
            onSelectionChanged: (s) => _setRange(s.first),
          ),
        ],
      ),
    );
  }

  Widget _rentalsCard() {
    return ReportCard<List<MonthValue>>(
      title: 'Rentals per month',
      icon: Icons.bar_chart,
      future: _rentals,
      isEmpty: ReportMath.isAllZero,
      emptyMessage: 'No rentals yet',
      onRetry: () =>
          setState(() => _rentals = _service.rentalsPerMonth(_range)),
      subtitle: (data) {
        final total = ReportMath.total(data).round();
        return '$total ${total == 1 ? 'rental' : 'rentals'} '
            'in the last ${_range.label}';
      },
      builder: (context, data) => MonthBarChart(
        values: data,
        color: AppColors.maroon,
        formatValue: (v) =>
            '${v.round()} ${v.round() == 1 ? 'rental' : 'rentals'}',
        formatAxis: (v) => v == v.roundToDouble() ? '${v.round()}' : '',
      ),
    );
  }

  Widget _revenueCard() {
    return ReportCard<List<MonthValue>>(
      title: 'Revenue per month',
      icon: Icons.payments_outlined,
      future: _revenue,
      isEmpty: ReportMath.isAllZero,
      emptyMessage: 'No payments recorded yet',
      onRetry: () =>
          setState(() => _revenue = _service.revenuePerMonth(_range)),
      subtitle: (data) =>
          '${Formatters.peso(ReportMath.total(data))} '
          'in the last ${_range.label}',
      builder: (context, data) => MonthBarChart(
        values: data,
        // UI audit #34: success green (about 5:1 on white) instead of
        // gold (about 2.3:1, below the 3:1 needed for chart bars).
        color: AppColors.success,
        formatValue: Formatters.peso,
        formatAxis: ReportMath.compactPeso,
      ),
    );
  }

  Widget _topItemsCard() {
    return ReportCard<List<TopItem>>(
      title: 'Most-rented items',
      icon: Icons.emoji_events_outlined,
      future: _topItems,
      isEmpty: (data) => data.isEmpty,
      emptyMessage: 'No rentals yet',
      onRetry: () => setState(() => _topItems = _service.topItems(_range)),
      subtitle: (_) => 'Top 5 in the last ${_range.label}',
      builder: (context, data) => TopItemsList(items: data),
    );
  }
}
