// My Bookings as order tabs (customer redesign, Phase 1):
//   To Pay | To Pick Up | Rented | Completed | Cancelled
// (grouping rules in shared/models/customer_booking_tab.dart). The tab can
// be chosen by link, e.g. /my-bookings?tab=to-pay, which is how the
// Profile shortcut icons open the right tab.
//
// All bookings are loaded once; each tab shows its share. Pull to refresh
// on every tab; loading, empty (per tab) and error with Retry states.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/services/my_bookings_service.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_card.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    this.initialTab = CustomerBookingTab.toPay,
  });

  /// Tab to open first (from ?tab=).
  final CustomerBookingTab initialTab;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = MyBookingsService();
  late Future<List<MyBooking>> _future;
  late final TabController _tabs = TabController(
    length: CustomerBookingTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );

  @override
  void initState() {
    super.initState();
    _future = _service.listMyBookings();
  }

  @override
  void didUpdateWidget(MyBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new ?tab= link (e.g. from Profile) switches the tab.
    if (widget.initialTab != oldWidget.initialTab) {
      _tabs.animateTo(widget.initialTab.index);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final next = _service.listMyBookings();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error state.
    }
  }

  Future<void> _openDetails(MyBooking booking) async {
    await context.pushNamed(
      RouteNames.customerBookingDetails,
      pathParameters: {'bookingId': booking.booking.id},
    );
    if (mounted) _reload(); // refresh in case it was cancelled
  }

  /// "Book again" on the Cancelled tab opens the item page.
  void _bookAgain(MyBooking booking) {
    if (booking.items.isEmpty) {
      _openDetails(booking);
      return;
    }
    context.go('${RoutePaths.browse}/item/${booking.items.first.id}');
  }

  static const Map<CustomerBookingTab, String> _emptyText = {
    CustomerBookingTab.toPay:
        'Nothing to pay. Reserve a gown or suit to start.',
    CustomerBookingTab.toPickUp: 'No reservations waiting for pick-up.',
    CustomerBookingTab.rented: 'You have nothing rented right now.',
    CustomerBookingTab.completed: 'Completed rentals will appear here.',
    CustomerBookingTab.cancelled: 'No cancelled or expired requests.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'My Bookings',
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // White on the maroon app bar; the selected tab is also bold
          // and underlined, so it is not shown by color alone.
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          tabs: [
            for (final tab in CustomerBookingTab.values) Tab(text: tab.label),
          ],
        ),
      ),
      body: FutureBuilder<List<MyBooking>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading your bookings...');
          }
          if (snap.hasError) {
            return ErrorView(
              message: 'Could not load your bookings. Please try again.',
              onRetry: _reload,
            );
          }
          final all = snap.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              for (final tab in CustomerBookingTab.values)
                _tabList(
                  tab,
                  all
                      .where((b) => CustomerBookingTab.of(b.booking) == tab)
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabList(CustomerBookingTab tab, List<MyBooking> bookings) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: bookings.isEmpty
          // Scrollable so pull to refresh still works when empty.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                EmptyView(
                  icon: Icons.receipt_long_outlined,
                  message: _emptyText[tab]!,
                  actionLabel: tab == CustomerBookingTab.toPay
                      ? 'Browse gowns and suits'
                      : null,
                  onAction: tab == CustomerBookingTab.toPay
                      ? () => context.goNamed(RouteNames.browse)
                      : null,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: bookings.length,
              itemBuilder: (context, i) => BookingCard(
                myBooking: bookings[i],
                onTap: () => _openDetails(bookings[i]),
                onAction: tab == CustomerBookingTab.cancelled
                    ? () => _bookAgain(bookings[i])
                    : null,
              ),
            ),
    );
  }
}
