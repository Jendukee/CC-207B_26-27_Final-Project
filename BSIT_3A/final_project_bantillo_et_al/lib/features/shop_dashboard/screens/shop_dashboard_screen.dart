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
// * Phones: one column. Wide screens (>= 840 px): two columns, with the
//   "New requests" card alone on the right and the other cards stacked on
//   the left, so incoming requests stay visible next to today's work (H1, H6).
//
// Shop-side redesign (Phase 2), the customer side's look:
// * light grey page with white rounded cards
// * summary tiles first (icon, count, label, "View"): 2 per row on phones,
//   3 from 600 px, all 5 in one row from 1000 px (H1, H6, H7)
// * then the alert lists in the My Bookings card style, with skeletons
//   while loading (H1, H4)
// The data, the five sections and every link are unchanged.
//
// Staff dashboard design (look only, same data, sections and links):
// * light blush page and a dark maroon header, the same height and title
//   size as the other staff screens (H4)
// * a maroon-to-red gradient hero with "Hi, <name>", today's date, a white
//   "View calendar" button (opens the Calendar tab by path) and the five
//   summary tiles on white cards with pink icon squares (H1, H6, H7)
// * below the hero (glance design): "Today at a glance" with the date and
//   four white cards (pick-ups, overdue, returns, expiring), each with a
//   tinted icon square, a summary line and "View more", plus a note that
//   pending requests are not pick-ups yet; and the "New requests since
//   yesterday" panel (NEW badge, count, rows with a Pending pill, "View
//   all booking requests →"). Side by side from 840 px, stacked on phones.
//   Same Futures, links, Retry and refresh as before (H1, H4, H6, H7).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/responsive_scaffold.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_hero.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_glance_card.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_requests_panel.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_summary_tile.dart';

/// The staff "Dashboard" screen.
class ShopDashboardScreen extends StatefulWidget {
  /// Creates the screen.
  const ShopDashboardScreen({super.key});

  /// Content width from which cards are shown in two columns.
  static const double twoColumnBreakpoint = 840;

  /// The section shown alone in the right column on wide screens.
  static const DashboardSection rightColumnSection =
      DashboardSection.newRequests;

  /// "Today at a glance" cards, in the design's order.
  static const List<DashboardSection> glanceSections = [
    DashboardSection.pickupsToday,
    DashboardSection.overdueReturns,
    DashboardSection.returnsToday,
    DashboardSection.expiringSoon,
  ];

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
    final name = SessionController.instance.user?.fullName?.trim();
    // Same width at which the shell shows the sidebar.
    final wide =
        MediaQuery.sizeOf(context).width >=
        ResponsiveScaffold.sidebarBreakpoint;
    return Scaffold(
      // Light blush page so the white cards stand out (design).
      backgroundColor: AppColors.blush,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      // Standard height and title size, the same as the Calendar and the
      // other staff screens (the taller header with the large title was
      // dropped); only the dark maroon color stays.
      appBar: BrandAppBar(
        title: 'Dashboard',
        backgroundColor: AppColors.maroonDeep,
        showLogo: false,
        titleSpacing: 40, 
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

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(wide ? 32 : 16),
              children: [
                DashboardHero(
                  greeting: (name == null || name.isEmpty)
                      ? 'Hi there'
                      : 'Hi, $name',
                  dateLine: 'Today is ${Formatters.date(_now)}',
                  // Calendar tab by path (no shop_calendar import).
                  onViewCalendar: () => context.go(RoutePaths.shopCalendar),
                  tiles: _summaryTiles(),
                ),
                SizedBox(height: wide ? 24 : 16),
                if (twoColumns)
                  _splitColumns()
                else ...[
                  _glanceColumn(),
                  const SizedBox(height: 16),
                  _requestsPanel(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// The five summary tiles (the hero lays them out in rows).
  List<Widget> _summaryTiles() => [
    for (final section in DashboardSection.values)
      DashboardSummaryTile(
        section: section,
        future: _futures[section]!,
        // Bookings tab, filtered (path only, no shop_bookings import).
        onView: () => context.go(DashboardDates.bookingsLink(section, _now)),
      ),
  ];

  /// Wide screens: "Today at a glance" on the left, "New requests" alone
  /// on the right. Each column keeps its own height, so a long list on one
  /// side leaves no gap on the other.
  Widget _splitColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _glanceColumn()),
        const SizedBox(width: 24),
        // Incoming requests, always in view next to today's work. Lined up
        // with the first glance card (below the heading).
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: _glanceHeadingHeight + 16),
            child: _requestsPanel(),
          ),
        ),
      ],
    );
  }

  /// Height of the "Today at a glance" heading row.
  static const double _glanceHeadingHeight = 28;

  /// "Today at a glance" + the date, the four glance cards (design order)
  /// and the note about pending requests.
  Widget _glanceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _glanceHeadingHeight,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: const Text(
                    'Today at a glance',
                    style: TextStyle(color: AppColors.inkDark, fontSize: 18),
                  ),
                ),
              ),
              Text(
                // e.g. "Tuesday, Nov 24"
                DateFormat('EEEE, MMM d').format(_now),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final section in ShopDashboardScreen.glanceSections)
          _glanceCard(section),
        // Why expiring / new requests are not counted as pick-ups.
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pending requests aren’t confirmed pick-ups yet.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// One glance card (same Future, links and Retry as before).
  Widget _glanceCard(DashboardSection section) {
    return DashboardGlanceCard(
      section: section,
      future: _futures[section]!,
      now: _now,
      onRetry: () => _retry(section),
      // Bookings tab, filtered (path only, no shop_bookings import).
      onOpenList: () => context.go(DashboardDates.bookingsLink(section, _now)),
      onOpenBooking: (id) => context.go('${RoutePaths.shopBookings}/$id'),
    );
  }

  /// The "New requests since yesterday" panel.
  Widget _requestsPanel() {
    const section = ShopDashboardScreen.rightColumnSection;
    return DashboardRequestsPanel(
      future: _futures[section]!,
      now: _now,
      onRetry: () => _retry(section),
      onOpenList: () => context.go(DashboardDates.bookingsLink(section, _now)),
      onOpenBooking: (id) => context.go('${RoutePaths.shopBookings}/$id'),
    );
  }
}
