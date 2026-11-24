// Record payment form (/shop/bookings/:bookingId/payment).
//
// * Kind: full / 50% down payment (before any payment) or balance (after).
// * Amount is pre-filled from the kind. Full and down amounts are fixed;
//   a balance payment may be partial.
// * Method: cash, GCash or bank transfer.
// * Shows the balance after this payment as staff type.
// * Validation (PaymentRules) is inline; the record_payment SQL function
//   checks the same rules again.
// * On success: snackbar, then back to the details screen with result true.
//
// Shop-side redesign (Phase 2): grey page with sectioned white cards (the
// booking summary, then "Payment" with kind, amount and method), and the
// sticky bar shows the balance after this payment on the left and "Save
// payment" on the right, like the customer checkout (H1, H4). The rules and
// the save call are unchanged.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/shop_bookings/models/booking_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/payment_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';
import 'package:orange150_rental/features/shop_bookings/services/shop_bookings_service.dart';
import 'package:orange150_rental/features/shop_bookings/widgets/detail_section.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// The staff "Record Payment" screen.
class RecordPaymentScreen extends StatefulWidget {
  /// Creates the screen for [bookingId].
  const RecordPaymentScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see shop_bookings_routes.dart).
  final String bookingId;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final ShopBookingsService _service = ShopBookingsService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();

  ShopBooking? _booking;
  String? _loadError;
  bool _loading = true;

  PaymentKind _kind = PaymentKind.full;
  PaymentMethod _method = PaymentMethod.cash;

  /// True while the payment is being saved.
  bool _submitting = false;

  /// Error from the server after submit (shown above the button).
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Retry button: show the spinner and load again.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _fetch();
  }

  /// Loads the booking and picks the default kind and amount.
  Future<void> _fetch() async {
    try {
      final booking = await _service.getBookingDetails(widget.bookingId);
      if (!mounted) return;
      final row = booking.booking;
      final kinds = PaymentRules.allowedKinds(paid: row.amountPaid);
      // Default: what the customer chose (full or 50%), or balance.
      final preferred = row.paymentOption == PaymentOption.half
          ? PaymentKind.down
          : PaymentKind.full;
      setState(() {
        _booking = booking;
        _loading = false;
        _kind = kinds.contains(preferred) ? preferred : kinds.first;
      });
      _fillAmount();
    } on ShopBookingsException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  /// Puts the suggested amount for [_kind] into the amount field.
  void _fillAmount() {
    final row = _booking!.booking;
    final amount = PaymentRules.suggestedAmount(
      _kind,
      total: row.totalAmount,
      paid: row.amountPaid,
    );
    _amount.text = amount.toStringAsFixed(2);
  }

  /// Changes the kind and refills the amount.
  void _onKindChanged(PaymentKind kind) {
    setState(() {
      _kind = kind;
      _submitError = null;
    });
    _fillAmount();
  }

  /// Validates and saves the payment.
  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = PaymentRules.parseAmount(_amount.text)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final updated = await _service.recordPayment(
        bookingId: widget.bookingId,
        amount: amount,
        kind: _kind,
        method: _method,
      );
      if (!mounted) return;
      final reservedNow =
          _booking!.booking.status == BookingStatus.pending &&
          updated.status == BookingStatus.reserved;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ${Formatters.peso(amount)} recorded.'
            '${reservedNow ? ' Booking is now Reserved.' : ''}',
          ),
        ),
      );
      // Back to the details screen. If this page was opened directly from
      // a URL there is nothing to pop, so go to the details instead.
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('${RoutePaths.shopBookings}/${widget.bookingId}');
      }
    } on ShopBookingsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final showForm =
        !_loading &&
        _loadError == null &&
        booking != null &&
        BookingRules.canRecordPayment(booking.booking);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: const BrandAppBar(title: 'Record Payment'),
      body: _buildBody(),
      // Customer redesign: the shared sticky bottom bar keeps Save payment
      // visible above the keyboard (same widget as the customer checkout).
      bottomNavigationBar: showForm
          ? StickyActionBar(
              // Phase 2: the live balance after this payment on the left.
              leading: _balanceAfterSummary(booking.booking),
              action: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_submitting ? 'Saving...' : 'Save payment'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Loading booking...');
    final booking = _booking;
    if (_loadError != null || booking == null) {
      return ErrorView(
        message: _loadError ?? 'Could not load this booking.',
        onRetry: _reload,
      );
    }

    final row = booking.booking;
    if (!BookingRules.canRecordPayment(row)) {
      final status = BookingRules.effectiveStatus(row);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            row.balance <= 0
                ? 'This booking is already paid in full.'
                : 'Payments cannot be recorded for a ${status.label} booking.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Keep the form readable on tablets and web.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summary(booking),
              // Phase 2: the form fields in one white card.
              SectionCard(
                title: 'Payment',
                icon: Icons.payments_outlined,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kindPicker(row),
                    const SizedBox(height: 16),
                    _amountField(row),
                    const SizedBox(height: 16),
                    _methodField(),
                  ],
                ),
              ),
              _runningBalance(row),
              if (_submitError != null) ...[
                const SizedBox(height: 16),
                NoticeBox(
                  icon: Icons.error_outline,
                  color: AppColors.deepRed,
                  text: _submitError!,
                ),
              ],
              // Save payment is in the sticky bottom bar (see build).
            ],
          ),
        ),
      ),
    );
  }

  /// Booking reference, customer and current amounts.
  Widget _summary(ShopBooking booking) {
    final row = booking.booking;
    return DetailSection(
      title: row.referenceNo,
      icon: Icons.receipt_outlined,
      children: [
        DetailRow(label: 'Customer', value: booking.customerName),
        DetailRow(label: 'Payment option', value: row.paymentOption.label),
        DetailRow(label: 'Total', value: Formatters.peso(row.totalAmount)),
        DetailRow(label: 'Paid so far', value: Formatters.peso(row.amountPaid)),
        DetailRow(
          label: 'Balance',
          value: Formatters.peso(row.balance),
          emphasize: true,
        ),
      ],
    );
  }

  /// Full / down / balance. Kinds that do not apply are disabled.
  Widget _kindPicker(Booking row) {
    final allowed = PaymentRules.allowedKinds(paid: row.amountPaid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment kind', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<PaymentKind>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: PaymentKind.full,
              label: const Text('Full'),
              enabled: allowed.contains(PaymentKind.full),
            ),
            ButtonSegment(
              value: PaymentKind.down,
              label: const Text('Down 50%'),
              enabled: allowed.contains(PaymentKind.down),
            ),
            ButtonSegment(
              value: PaymentKind.balance,
              label: const Text('Balance'),
              enabled: allowed.contains(PaymentKind.balance),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: _submitting
              ? null
              : (selection) => _onKindChanged(selection.first),
        ),
      ],
    );
  }

  /// Amount in pesos. Read-only for full and down payments.
  Widget _amountField(Booking row) {
    final fixed = _kind != PaymentKind.balance;
    return TextFormField(
      controller: _amount,
      readOnly: fixed,
      enabled: !_submitting,
      // UI audit #16: digits and one decimal point (max 2 decimals) only.
      inputFormatters: Validators.moneyFormatters,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '₱ ',
        helperText: fixed
            ? 'Set by the payment kind.'
            : 'Up to ${Formatters.peso(row.balance)}. Partial payments are OK.',
      ),
      // Rebuild the running balance as staff type.
      onChanged: (_) => setState(() => _submitError = null),
      validator: (value) => PaymentRules.validateAmount(
        value,
        kind: _kind,
        total: row.totalAmount,
        paid: row.amountPaid,
      ),
    );
  }

  /// Cash / GCash / bank transfer.
  Widget _methodField() {
    return DropdownButtonFormField<PaymentMethod>(
      initialValue: _method,
      decoration: const InputDecoration(labelText: 'Payment method'),
      items: [
        for (final method in PaymentMethod.values)
          DropdownMenuItem(value: method, child: Text(method.label)),
      ],
      onChanged: _submitting
          ? null
          : (method) => setState(() => _method = method ?? _method),
      validator: (method) => method == null ? 'Choose a payment method.' : null,
    );
  }

  /// The balance left after the amount typed so far (same PaymentRules).
  double _balanceAfter(Booking row) {
    final amount = PaymentRules.parseAmount(_amount.text) ?? 0;
    return PaymentRules.balance(
      total: row.totalAmount,
      paid: row.amountPaid + (amount > 0 ? amount : 0),
    );
  }

  /// "Balance after ₱X" on the left of the sticky bar (Phase 2).
  Widget _balanceAfterSummary(Booking row) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Balance after', style: theme.textTheme.bodySmall),
        Text(
          Formatters.peso(_balanceAfter(row)),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.maroon,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// "Balance after this payment: ₱X", updated live.
  Widget _runningBalance(Booking row) {
    final after = _balanceAfter(row);
    final theme = Theme.of(context);
    return Card(
      color: AppColors.goldTint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Balance after this payment',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              Formatters.peso(after),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
