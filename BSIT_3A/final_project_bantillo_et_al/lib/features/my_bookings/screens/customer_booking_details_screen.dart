// Customer booking details, laid out like an order page (customer
// redesign, Phase 1):
//   * header: only the title and the reference number (customer redesign
//     2; the status banner left the header)
//   * "Booking status" FIRST card (shared BookingStatusCard): status chip,
//     the status in words, what to do next, the payment deadline, the
//     timeline (Requested, Reserved, Picked up, Returned) and ONE action:
//     "How to pay" while Pending (scrolls to that card), otherwise
//     "Contact the shop" (H1, H2, H8)
//   * Item, Rental schedule and Payment cards (paid, balance, method)
//   * the signed agreement: "Signed as <name> on <date>" and "View signed
//     agreement", which opens the exact form saved at signing (Phase 2)
//   * "Contact the shop" and, while allowed, "Cancel booking" (asks first)
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/agreement_document.dart';
import 'package:orange150_rental/core/widgets/booking_status_card.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/contact_shop.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/payment_instructions.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/my_bookings/models/booking_details.dart';
import 'package:orange150_rental/features/my_bookings/models/customer_status_text.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/services/my_bookings_service.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_formatters.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/payment.dart';

class CustomerBookingDetailsScreen extends StatefulWidget {
  const CustomerBookingDetailsScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see my_bookings_routes.dart).
  final String bookingId;

  @override
  State<CustomerBookingDetailsScreen> createState() =>
      _CustomerBookingDetailsScreenState();
}

class _CustomerBookingDetailsScreenState
    extends State<CustomerBookingDetailsScreen> {
  final _service = MyBookingsService();
  late Future<BookingDetails> _future;
  bool _cancelling = false;

  /// The "How to pay" card, scrolled to from the status card.
  final GlobalKey _howToPayKey = GlobalKey(debugLabel: 'howToPay');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<BookingDetails> _load() async {
    final results = await Future.wait<Object>([
      _service.getBooking(widget.bookingId),
      _service.listPayments(widget.bookingId),
      _service.checklistDates(widget.bookingId),
    ]);
    return BookingDetails(
      myBooking: results[0] as MyBooking,
      payments: results[1] as List<Payment>,
      checklistDates: results[2] as Map<String, DateTime>,
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cancelling = true);
    try {
      await _service.cancelBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      setState(() {
        _cancelling = false;
        _future = _load();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      // Phase 3: show the database's reason (e.g. the booking was paid
      // and is now Reserved, so it is non-refundable).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              e,
              fallback: 'Could not cancel. Please try again.',
            ),
          ),
        ),
      );
      setState(() => _future = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4),
      // showing only the title and, once loaded, the reference number.
      appBar: BrandAppBar(
        titleWidget: FutureBuilder<BookingDetails>(
          future: _future,
          builder: (context, snap) => _HeaderTitle(
            reference: snap.hasData ? snap.data!.booking.referenceNo : null,
          ),
        ),
      ),
      body: FutureBuilder<BookingDetails>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading booking...');
          }
          // UI audit #15: the error state has a Retry button.
          if (snap.hasError) {
            return ErrorView(
              message: 'Could not load this booking. Please try again.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          return _content(snap.data!, theme);
        },
      ),
    );
  }

  Widget _content(BookingDetails d, ThemeData theme) {
    final b = d.booking;
    final status = b.displayStatus();
    const gap = EdgeInsets.fromLTRB(8, 0, 8, 8);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future.catchError((_) => d);
      },
      // Customer redesign 2: a Column in a scroll view (not a lazy
      // ListView), so "How to pay" can always scroll to its card.
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer redesign 2: everything about the status in the FIRST
            // card (it replaces the maroon banner and the Progress card).
            BookingStatusCard(
              status: status,
              statusText: CustomerStatusText.words(status),
              nextStep: CustomerStatusText.nextStep(b),
              deadline: status == BookingStatus.pending ? b.expiresAt : null,
              steps: [
                for (final s in d.timeline) (label: s.label, date: s.date),
              ],
              // One action: how to pay while Pending, otherwise the shop.
              action: status == BookingStatus.pending
                  ? FilledButton.icon(
                      onPressed: _scrollToHowToPay,
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('How to pay'),
                    )
                  : const ContactShopButton(outlined: true),
            ),

            // The status chip is in the status card now (H8: shown once).
            SectionCard(
              title: 'Item',
              icon: Icons.checkroom_outlined,
              margin: gap,
              child: Column(
                children: [
                  if (d.items.isEmpty) const Text('No items found.'),
                  for (final item in d.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.square(
                          dimension: 56,
                          child: item.photoUrls.isEmpty
                              ? const Icon(Icons.checkroom)
                              : Image.network(
                                  item.photoUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.checkroom),
                                ),
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text('${item.type.label} · Size ${item.size}'),
                    ),
                ],
              ),
            ),

            SectionCard(
              title: 'Rental schedule',
              icon: Icons.event_outlined,
              margin: gap,
              child: Column(
                children: [
                  _row('Pick-up', formatDate(b.pickupDate)),
                  _row('Event', formatDate(b.eventDate)),
                  _row('Return', formatDate(b.returnDate)),
                ],
              ),
            ),

            SectionCard(
              title: 'Payment',
              icon: Icons.payments_outlined,
              margin: gap,
              child: Column(
                children: [
                  _row('Option', b.paymentOption.label),
                  _row('Total', formatPeso(b.totalAmount)),
                  _row('Paid', formatPeso(b.amountPaid)),
                  _row('Balance', formatPeso(b.balance), bold: true),
                  if (d.payments.isNotEmpty) _row('Method', d.methodsUsed),
                  if (payByText(b) != null) _row('Deadline', payByText(b)!),
                  if (d.payments.isNotEmpty) const Divider(),
                  for (final p in d.payments)
                    _row(
                      '${p.kind.label} · ${formatDateOrDash(p.createdAt)}',
                      formatPeso(p.amount),
                    ),
                ],
              ),
            ),

            // Phase 3: a booking waiting for payment shows how to pay, with the
            // GCash number and shop contact numbers pre-filled (the same card as
            // the "Request submitted" screen).
            if (status == BookingStatus.pending)
              SectionCard(
                key: _howToPayKey, // target of the status card's "How to pay"
                title: 'How to pay',
                icon: Icons.account_balance_wallet_outlined,
                margin: gap,
                child: PaymentInstructions(
                  method: b.preferredPaymentMethod,
                  referenceNo: b.referenceNo,
                ),
              ),

            SectionCard(
              title: 'Rental agreement',
              icon: Icons.assignment_turned_in_outlined,
              margin: gap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 2: the typed signature and the exact agreement.
                  Text(
                    b.isSigned
                        ? 'Signed as ${b.signedName}'
                              '${b.termsAcknowledgedAt == null ? '' : ' on ${Formatters.dateTime(b.termsAcknowledgedAt!)}'}'
                              '${b.termsVersion == null ? '' : ' (terms version ${b.termsVersion})'}.'
                        : b.termsAcknowledgedAt == null
                        ? 'No signed agreement is saved for this booking.'
                        : 'You agreed to the rental terms on '
                              '${Formatters.dateTime(b.termsAcknowledgedAt!)}.',
                  ),
                  if (b.preferredFittingDate != null)
                    Text(
                      'Preferred fitting date: '
                      '${formatDate(b.preferredFittingDate!)}',
                    ),
                  // Signed bookings show the saved form; older ones the
                  // current terms.
                  TextButton(
                    onPressed: b.termsSnapshot == null
                        ? () => _showTerms(context)
                        : () => showSignedAgreement(
                            context,
                            snapshot: b.termsSnapshot!,
                            signedName: b.signedName ?? '',
                            signedAt: b.termsAcknowledgedAt,
                            version: b.termsVersion,
                            customerFullName: b.customerFullName,
                          ),
                    child: Text(
                      b.termsSnapshot == null
                          ? 'View rental terms'
                          : 'View signed agreement',
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phase 3: a Reserved booking cannot be cancelled by the
                  // customer; this explains why and points to the shop.
                  if (d.showNonRefundableNotice) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.maroon,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(BookingDetails.nonRefundableNotice),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // While Pending the status card's action is "How to pay", so
                  // the shop contact stays here; otherwise the status card
                  // already has it (H8: not shown twice).
                  if (status == BookingStatus.pending)
                    const ContactShopButton(outlined: true),
                  // Phase 3: Pending only (see BookingDetails.canCancel).
                  if (d.canCancel) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepRed,
                      ),
                      onPressed: _cancelling ? null : _confirmCancel,
                      child: _cancelling
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cancel booking'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scrolls the "How to pay" card into view (status card action).
  void _scrollToHowToPay() {
    final target = _howToPayKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shows the shop's numbered rental terms.
void _showTerms(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rental terms'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < RentalTerms.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${i + 1}. ${RentalTerms.items[i]}'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Header title: "Booking Details" and, once loaded, "Ref O150-..."
/// (customer redesign 2: the status itself is in the status card).
class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({this.reference});

  final String? reference;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking Details', maxLines: 1),
        if (reference != null)
          Text(
            'Ref $reference',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
          ),
      ],
    );
  }
}
