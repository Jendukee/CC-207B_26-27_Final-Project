// Staff booking details: customer, measurements snapshot, items, dates,
// payment summary and history, e-contract indicator and the status actions
// allowed by BookingRules:
//   * Record payment  -> /shop/bookings/:bookingId/payment
//   * Mark picked up  -> /shop/checklist/release/:bookingId (checklist feature)
//   * Mark returned   -> /shop/checklist/return/:bookingId  (checklist feature)
//   * Cancel booking  -> confirmation dialog, then update_booking_status
// The checklist screens are opened BY PATH; this feature does not import
// the checklist feature.
//
// Used two ways: as a full page (/shop/bookings/:bookingId) and, with
// embedded: true, as the side panel of the bookings list on wide screens.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/agreement_document.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_bookings/models/booking_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/payment_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';
import 'package:orange150_rental/features/shop_bookings/services/shop_bookings_service.dart';
import 'package:orange150_rental/features/shop_bookings/widgets/detail_section.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// The staff "Booking Details" screen.
class ShopBookingDetailsScreen extends StatefulWidget {
  /// Creates the screen for [bookingId].
  const ShopBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.embedded = false,
    this.onChanged,
  });

  /// Path parameter from the route (see shop_bookings_routes.dart).
  final String bookingId;

  /// True inside the list's side panel: no Scaffold / AppBar of its own.
  final bool embedded;

  /// Called after this screen changed the booking (payment, cancel...),
  /// so the list can refresh.
  final VoidCallback? onChanged;

  /// Width from which sections are shown in two columns.
  static const double twoColumnBreakpoint = 760;

  @override
  State<ShopBookingDetailsScreen> createState() =>
      _ShopBookingDetailsScreenState();
}

class _ShopBookingDetailsScreenState extends State<ShopBookingDetailsScreen> {
  final ShopBookingsService _service = ShopBookingsService();

  ShopBooking? _booking;
  String? _error;
  bool _loading = true;

  /// True while a cancel request is running.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Shows the spinner again, then loads (Retry button).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  /// Loads the booking. Old data stays on screen while it loads, so
  /// pull-to-refresh does not flash a spinner.
  Future<void> _fetch() async {
    try {
      final booking = await _service.getBookingDetails(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _error = null;
        _loading = false;
      });
    } on ShopBookingsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// Reloads and tells the list something changed.
  Future<void> _afterChange() async {
    widget.onChanged?.call();
    await _fetch();
  }

  /// Opens a route and reloads when coming back.
  Future<void> _pushAndReload(String path) async {
    await context.push<Object?>(path);
    if (mounted) await _afterChange();
  }

  /// Record payment form (same feature).
  void _recordPayment() =>
      _pushAndReload('${RoutePaths.shopBookings}/${widget.bookingId}/payment');

  /// Release checklist (checklist feature, by path).
  void _markPickedUp() => _pushAndReload(
    RoutePaths.releaseChecklist.replaceFirst(':bookingId', widget.bookingId),
  );

  /// Return checklist (checklist feature, by path).
  void _markReturned() => _pushAndReload(
    RoutePaths.returnChecklist.replaceFirst(':bookingId', widget.bookingId),
  );

  /// Asks for confirmation, then cancels.
  Future<void> _cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Booking ${booking.referenceNo} will be cancelled and its dates '
          'freed for other customers. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.cancelBooking(booking.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Booking ${booking.referenceNo} cancelled.')),
      );
      await _afterChange();
    } on ShopBookingsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(_booking?.booking.referenceNo ?? 'Booking Details'),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading && _booking == null) {
      return const LoadingView(message: 'Loading booking...');
    }
    final booking = _booking;
    if (_error != null || booking == null) {
      return ErrorView(
        message: _error ?? 'Could not load this booking.',
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns =
              constraints.maxWidth >=
              ShopBookingDetailsScreen.twoColumnBreakpoint;

          final left = [
            _header(booking),
            _customerSection(booking),
            _measurementsSection(booking.booking),
            _itemsSection(booking),
            _contractSection(booking.booking),
          ];
          final right = [
            _actionsSection(booking.booking),
            _paymentSection(booking.booking),
            _historySection(booking),
          ];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: twoColumns
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: left)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(children: right)),
                    ],
                  )
                // Phones: actions right after the header.
                : Column(children: [left.first, ...right, ...left.skip(1)]),
          );
        },
      ),
    );
  }

  /// Reference, status chip and the expired notice.
  Widget _header(ShopBooking booking) {
    final row = booking.booking;
    final status = BookingRules.effectiveStatus(row);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.referenceNo, style: theme.textTheme.titleLarge),
              ),
              StatusChip.booking(status),
            ],
          ),
          if (row.createdAt != null)
            Text(
              'Requested ${Formatters.dateTime(row.createdAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          if (BookingRules.isPastExpiry(row))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NoticeBox(
                icon: Icons.timer_off_outlined,
                color: AppColors.neutralGrey,
                text:
                    'This request expired on '
                    '${Formatters.dateTime(row.expiresAt!)} without payment.',
              ),
            ),
        ],
      ),
    );
  }

  /// Customer name and mobile number.
  Widget _customerSection(ShopBooking booking) {
    final phone = booking.customerPhone ?? '';
    final row = booking.booking;
    return DetailSection(
      title: 'Customer',
      icon: Icons.person_outline,
      children: [
        DetailRow(label: 'Name', value: booking.customerName),
        // The name given at checkout (0012); the signature is checked
        // against it, and it can differ from the account name.
        if ((row.customerFullName ?? '').isNotEmpty)
          DetailRow(label: 'Name on booking', value: row.customerFullName!),
        DetailRow(
          label: 'Mobile',
          value: phone.isEmpty ? 'Not provided' : phone,
        ),
        // E-contract details given at checkout (Phase 2), when present.
        if ((row.facebookAccount ?? '').isNotEmpty)
          DetailRow(label: 'Facebook', value: row.facebookAccount!),
        if ((row.customerAddress ?? '').isNotEmpty)
          DetailRow(label: 'Address', value: row.customerAddress!),
        if (row.preferredPaymentMethod != null)
          DetailRow(
            label: 'Will pay by',
            value: PaymentMethod.labelFor(row.preferredPaymentMethod!),
          ),
        if (row.preferredFittingDate != null)
          DetailRow(
            label: 'Fitting date',
            value: Formatters.date(row.preferredFittingDate!),
          ),
        if ((row.notes ?? '').isNotEmpty)
          DetailRow(label: 'Note', value: row.notes!),
      ],
    );
  }

  /// Measurements copied into the booking when the customer booked.
  Widget _measurementsSection(Booking booking) {
    const labels = {
      'chest': 'Chest',
      'waist': 'Waist',
      'hips': 'Hips',
      'shoulder': 'Shoulder',
      'height': 'Height',
      'inseam': 'Inseam',
    };
    final snapshot = booking.measurementsSnapshot ?? const {};
    final rows = <Widget>[
      for (final entry in labels.entries)
        if (snapshot[entry.key] != null)
          DetailRow(label: entry.value, value: '${snapshot[entry.key]} in'),
    ];
    final notes = (snapshot['notes'] as String? ?? '').trim();

    return DetailSection(
      title: 'Measurements',
      icon: Icons.straighten,
      children: [
        if (rows.isEmpty && notes.isEmpty)
          const Text('No measurements were saved with this booking.'),
        ...rows,
        if (notes.isNotEmpty) DetailRow(label: 'Notes', value: notes),
      ],
    );
  }

  /// Items and rental dates.
  Widget _itemsSection(ShopBooking booking) {
    final row = booking.booking;
    return DetailSection(
      title: 'Items and dates',
      icon: Icons.checkroom_outlined,
      children: [
        if (booking.items.isEmpty) const Text('No items on this booking.'),
        for (final item in booking.items)
          DetailRow(
            label: '${item.name} (${item.type.label}, size ${item.size})',
            value: Formatters.peso(item.price),
          ),
        const Divider(),
        DetailRow(label: 'Pick-up', value: Formatters.date(row.pickupDate)),
        DetailRow(label: 'Event', value: Formatters.date(row.eventDate)),
        DetailRow(label: 'Return', value: Formatters.date(row.returnDate)),
      ],
    );
  }

  /// "Customer acknowledged rental terms on (date)" or a warning.
  Widget _contractSection(Booking booking) {
    final acknowledgedAt = booking.termsAcknowledgedAt;
    final version = booking.termsVersion;
    return DetailSection(
      title: 'E-contract',
      icon: Icons.assignment_turned_in_outlined,
      children: [
        // Phase 2: bookings signed with a typed name.
        if (booking.isSigned)
          NoticeBox(
            icon: Icons.verified_outlined,
            color: AppColors.success,
            text:
                'Customer signed as ${booking.signedName}'
                '${acknowledgedAt == null ? '' : ' on ${Formatters.dateTime(acknowledgedAt)}'}'
                '${version == null ? '' : ' (terms version $version)'}.',
          )
        else if (acknowledgedAt != null)
          NoticeBox(
            icon: Icons.verified_outlined,
            color: AppColors.success,
            text:
                'Customer acknowledged rental terms on '
                '${Formatters.dateTime(acknowledgedAt)}'
                '${version == null ? '' : ' (version $version)'}.',
          )
        else
          const NoticeBox(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warningOrange,
            text:
                'The customer has NOT acknowledged the rental terms. '
                'Ask them to accept the terms before releasing the items.',
          ),
        if (booking.termsSnapshot != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showSignedAgreement(
                context,
                snapshot: booking.termsSnapshot!,
                signedName: booking.signedName ?? '',
                signedAt: acknowledgedAt,
                version: version,
                customerFullName: booking.customerFullName,
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View signed agreement'),
            ),
          ),
      ],
    );
  }

  /// Total, paid, balance and payment option.
  Widget _paymentSection(Booking booking) {
    return DetailSection(
      title: 'Payment',
      icon: Icons.payments_outlined,
      children: [
        DetailRow(label: 'Payment option', value: booking.paymentOption.label),
        DetailRow(label: 'Total', value: Formatters.peso(booking.totalAmount)),
        DetailRow(
          label: 'Amount paid',
          value: Formatters.peso(booking.amountPaid),
        ),
        DetailRow(
          label: 'Balance',
          value: Formatters.peso(booking.balance),
          emphasize: true,
        ),
        DetailRow(
          label: 'Status',
          value: BookingRules.paymentStatusLabel(booking),
        ),
      ],
    );
  }

  /// List of recorded payments.
  Widget _historySection(ShopBooking booking) {
    return DetailSection(
      title: 'Payment history',
      icon: Icons.receipt_long_outlined,
      children: [
        if (booking.payments.isEmpty) const Text('No payments recorded yet.'),
        for (final payment in booking.payments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              '${Formatters.peso(payment.amount)} · ${payment.kind.label}',
            ),
            subtitle: Text(
              [
                PaymentMethod.labelFor(payment.method),
                if (payment.createdAt != null)
                  Formatters.dateTime(payment.createdAt!),
              ].join(' · '),
            ),
          ),
      ],
    );
  }

  /// Buttons for the transitions allowed right now.
  Widget _actionsSection(Booking booking) {
    final status = BookingRules.effectiveStatus(booking);
    final buttons = <Widget>[
      if (BookingRules.canRecordPayment(booking))
        FilledButton.icon(
          onPressed: _busy ? null : _recordPayment,
          icon: const Icon(Icons.add_card),
          label: Text(
            booking.status == BookingStatus.pending
                ? 'Record payment to reserve'
                : 'Record balance payment',
          ),
        ),
      // UI audit #31: only ONE filled (primary) button. While a balance
      // is owed, "Record balance payment" is primary and this is outlined.
      if (BookingRules.canMarkPickedUp(booking))
        BookingRules.canRecordPayment(booking)
            ? OutlinedButton.icon(
                onPressed: _busy ? null : _markPickedUp,
                icon: const Icon(Icons.outbox_outlined),
                label: const Text('Mark picked up'),
              )
            : FilledButton.icon(
                onPressed: _busy ? null : _markPickedUp,
                icon: const Icon(Icons.outbox_outlined),
                label: const Text('Mark picked up'),
              ),
      if (BookingRules.canMarkReturned(booking))
        FilledButton.icon(
          onPressed: _busy ? null : _markReturned,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Mark returned'),
        ),
      if (BookingRules.canCancel(booking))
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepRed),
          onPressed: _busy ? null : () => _cancel(booking),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cancel_outlined),
          label: const Text('Cancel booking'),
        ),
    ];

    return DetailSection(
      title: 'Actions',
      icon: Icons.bolt_outlined,
      children: [
        if (buttons.isEmpty)
          Text('No actions available for ${status.label} bookings.'),
        if (BookingRules.canMarkPickedUp(booking) && booking.balance > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NoticeBox(
              icon: Icons.info_outline,
              color: AppColors.warningOrange,
              text:
                  'Balance of ${Formatters.peso(booking.balance)} must be '
                  'paid before the items can be released.',
            ),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ],
    );
  }
}
