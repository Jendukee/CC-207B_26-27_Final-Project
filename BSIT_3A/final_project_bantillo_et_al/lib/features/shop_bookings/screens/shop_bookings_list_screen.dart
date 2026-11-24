// Staff bookings list (Bookings tab of the staff shell).
//
// * Search by reference number or customer name, status chips and an
//   event-date range (BookingFilterBar).
// * Phones: tapping a booking opens /shop/bookings/:bookingId.
// * Wide screens (>= 840 px of content): list on the left, details of the
//   selected booking on the right.
// * The filter can come from the URL, e.g. /shop/bookings?status=reserved
//   (see models/shop_booking_filter.dart), so the dashboard can link here.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/widgets/async_list_view.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking_filter.dart';
import 'package:orange150_rental/features/shop_bookings/screens/shop_booking_details_screen.dart';
import 'package:orange150_rental/features/shop_bookings/services/shop_bookings_service.dart';
import 'package:orange150_rental/features/shop_bookings/widgets/booking_filter_bar.dart';
import 'package:orange150_rental/features/shop_bookings/widgets/shop_booking_card.dart';

/// The staff "Bookings" screen.
class ShopBookingsListScreen extends StatefulWidget {
  /// Creates the screen. [initialFilter] comes from the URL query.
  const ShopBookingsListScreen({
    super.key,
    this.initialFilter = const ShopBookingFilter(),
  });

  /// Filter to start with.
  final ShopBookingFilter initialFilter;

  /// Content width from which list and details sit side by side.
  static const double splitBreakpoint = 840;

  @override
  State<ShopBookingsListScreen> createState() => _ShopBookingsListScreenState();
}

class _ShopBookingsListScreenState extends State<ShopBookingsListScreen> {
  final ShopBookingsService _service = ShopBookingsService();

  late ShopBookingFilter _filter = widget.initialFilter;

  /// Booking shown in the side panel on wide screens.
  String? _selectedId;

  /// Bumped to force AsyncListView to load again (e.g. after a change in
  /// the side panel).
  int _reloadCount = 0;

  @override
  void didUpdateWidget(ShopBookingsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new URL (e.g. a dashboard card) brought a different filter.
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() => _filter = widget.initialFilter);
    }
  }

  /// Applies a new filter from the filter bar.
  void _onFilterChanged(ShopBookingFilter filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
  }

  /// Reloads the list (keeps the filter and selection).
  void _reload() => setState(() => _reloadCount++);

  /// Opens a booking: side panel when wide, full page otherwise.
  Future<void> _open(ShopBooking booking, {required bool wide}) async {
    if (wide) {
      setState(() => _selectedId = booking.booking.id);
      return;
    }
    await context.push('${RoutePaths.shopBookings}/${booking.booking.id}');
    // The booking may have changed (payment, cancel), so refresh.
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'Bookings',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= ShopBookingsListScreen.splitBreakpoint;
          final list = _buildList(wide: wide);
          if (!wide) return list;

          return Row(
            children: [
              SizedBox(width: 400, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: _buildSidePanel()),
            ],
          );
        },
      ),
    );
  }

  /// Filter bar + list of booking cards.
  Widget _buildList({required bool wide}) {
    return Column(
      children: [
        BookingFilterBar(filter: _filter, onChanged: _onFilterChanged),
        const Divider(height: 16),
        Expanded(
          child: AsyncListView<ShopBooking>(
            // A new key = a new AsyncListView = a fresh load.
            key: ValueKey(Object.hash(_filter, _reloadCount)),
            load: () => _service.listBookings(_filter),
            emptyMessage: 'No bookings match your filters',
            errorMessage:
                'Could not load bookings. Check your connection and try again.',
            itemBuilder: (context, booking) => ShopBookingCard(
              booking: booking,
              selected: wide && booking.booking.id == _selectedId,
              onTap: () => _open(booking, wide: wide),
            ),
          ),
        ),
      ],
    );
  }

  /// Right-hand panel on wide screens.
  Widget _buildSidePanel() {
    final id = _selectedId;
    if (id == null) {
      return const EmptyView(
        icon: Icons.touch_app_outlined,
        message: 'Select a booking to see its details.',
      );
    }
    return ShopBookingDetailsScreen(
      key: ValueKey(id),
      bookingId: id,
      embedded: true,
      onChanged: _reload,
    );
  }
}
