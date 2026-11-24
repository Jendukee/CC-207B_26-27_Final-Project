// Staff dashboard (Dashboard tab, the staff home):
//   pick-ups today, returns today, overdue returns, requests expiring in
//   24 hours and new requests since yesterday.
//
// * Each card shows a count and up to 5 bookings, with its own loading,
//   empty and error (Retry) state.
// * Tapping a card opens the shop bookings list filtered by path query
//   parameters (see DashboardDates.bookingsLink); tapping a booking opens
//   its details. Both go to the Bookings tab by path, no imports.
// * Pull to refresh reloads every card.
// * Phones: one column. Wide screens (>= 840 px): a 2-column grid.
//
// Shop-side redesign (Phase 2), the customer side's look:
// * light grey page with white rounded cards
// * summary tiles first (icon, count, label, "View"): 2 per row on phones,
//   3 from 600 px, all 5 in one row from 1000 px (H1, H6, H7)
// * then the alert lists in the My Bookings card style, with skeletons
//   while loading (H1, H4)
// The data, the five sections and every link are unchanged.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_section_card.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_summary_tile.dart';

/// The staff "Dashboard" screen.
class ShopDashboardScreen extends StatefulWidget {
  /// Creates the screen.
  const ShopDashboardScreen({super.key});

  /// Content width from which cards are shown in two columns.
  static const double twoColumnBreakpoint = 840;

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  final ShopDashboardService _service = ShopDashboardService();

  /// One Future per card, so each card loads and fails on its own.
  final Map<DashboardSection, Future<List<DashboardBooking>>> _futures = {};

  /// The time the cards were loaded for.
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Starts loading every card (no setState: also used by initState).
  void _loadAll() {
    _now = DateTime.now();
    for (final section in DashboardSection.values) {
      _futures[section] = _service.load(section, now: _now);
    }
  }

  /// Pull to refresh: reload every card and wait until all are done.
  Future<void> _refresh() async {
    setState(_loadAll);
    // Errors are shown inside each card, so ignore them here.
    await Future.wait(
      _futures.values.map((f) => f.then((_) {}, onError: (_) {})),
    );
  }

  /// Retry button of one card.
  void _retry(DashboardSection section) {
    setState(() => _futures[section] = _service.load(section, now: _now));
  }

  @override
  Widget build(BuildContext context) {
    final name = SessionController.instance.user?.fullName;
    return Scaffold(
      // Light grey page so the white cards stand out (as on the customer
      // side).
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'Dashboard',
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
            final twoColumns =
                constraints.maxWidth >= ShopDashboardScreen.twoColumnBreakpoint;
            final cards = [
              for (final section in DashboardSection.values) _card(section),
            ];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  (name == null || name.isEmpty)
                      ? 'Today, ${Formatters.date(_now)}'
                      : 'Hi $name. Today is ${Formatters.date(_now)}.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _summaryGrid(constraints.maxWidth - 32),
                const SizedBox(height: 16),
                if (twoColumns) ..._pairs(cards) else ...cards,
              ],
            );
          },
        ),
      ),
    );
  }

  /// The summary tiles, in rows of 2, 3 or 5 depending on [width].
  Widget _summaryGrid(double width) {
    final perRow = width >= 1000
        ? 5
        : width >= 600
        ? 3
        : 2;
    const gap = 8.0;
    final tileWidth = (width - gap * (perRow - 1)) / perRow;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final section in DashboardSection.values)
          SizedBox(
            width: tileWidth,
            child: DashboardSummaryTile(
              section: section,
              future: _futures[section]!,
              // Bookings tab, filtered (path only, no shop_bookings import).
              onView: () =>
                  context.go(DashboardDates.bookingsLink(section, _now)),
            ),
          ),
      ],
    );
  }

  /// Puts cards side by side, two per row.
  List<Widget> _pairs(List<Widget> cards) {
    return [
      for (var i = 0; i < cards.length; i += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
            ),
          ],
        ),
    ];
  }

  /// The card for one section.
  Widget _card(DashboardSection section) {
    return DashboardSectionCard(
      section: section,
      future: _futures[section]!,
      now: _now,
      onRetry: () => _retry(section),
      // Bookings tab, filtered (path only, no shop_bookings import).
      onOpenList: () => context.go(DashboardDates.bookingsLink(section, _now)),
      onOpenBooking: (id) => context.go('${RoutePaths.shopBookings}/$id'),
    );
  }
}
