// Customer booking details, laid out like an order page (customer
// redesign, Phase 1):
//   * a maroon status banner that says what to do next
//   * a vertical timeline: Requested, Reserved, Picked up, Returned
//   * Item, Rental schedule and Payment cards (paid, balance, method)
//   * the signed agreement: "Signed as <name> on <date>" and "View signed
//     agreement", which opens the exact form saved at signing (Phase 2)
//   * "Contact the shop" and, while allowed, "Cancel booking" (asks first)
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/agreement_document.dart';
import 'package:orange150_rental/core/widgets/contact_shop.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/my_bookings/models/booking_details.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/services/my_bookings_service.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_formatters.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_status_badge.dart';
import 'package:orange150_rental/features/reservation/models/payment_plan.dart';
import 'package:orange150_rental/shared/models/booking.dart';
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel. Please try again.')),
      );
    }
  }

  /// The banner's "what to do next" text for each displayed status.
  static String nextStep(Booking b) {
    final payNow = PaymentPlan.dueNow(b.totalAmount, b.paymentOption);
    final deadline = b.expiresAt;
    return switch (b.displayStatus()) {
      BookingStatus.pending =>
        'Pay ${formatPeso(payNow)}'
            '${deadline == null ? '' : ' by ${Formatters.dateTime(deadline)}'}'
            ' to reserve your dates. GCash: ${ShopContact.gcash}.',
      BookingStatus.reserved =>
        'Reserved! Pick up on ${formatDate(b.pickupDate)} at the shop.'
            '${b.balance > 0 ? ' Bring the balance of ${formatPeso(b.balance)}.' : ''}',
      BookingStatus.rentedOut =>
        'Enjoy your event! Please return it by ${formatDate(b.returnDate)}.',
      BookingStatus.returned => 'Returned. Thank you for renting with us!',
      BookingStatus.cancelled => 'This booking was cancelled.',
      BookingStatus.expired =>
        'This request expired because it was not paid in time.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(title: const Text('Booking Details')),
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
    const gap = EdgeInsets.fromLTRB(8, 0, 8, 8);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future.catchError((_) => d);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Status banner: what to do next.
          Container(
            color: AppColors.maroon,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.displayStatus().label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onMaroon,
                        ),
                      ),
                    ),
                    Text(
                      'Ref ${b.referenceNo}',
                      style: const TextStyle(color: AppColors.onMaroon),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nextStep(b),
                  style: const TextStyle(color: AppColors.onMaroon),
                ),
              ],
            ),
          ),

          SectionCard(
            title: 'Progress',
            icon: Icons.timeline,
            margin: gap,
            child: _Timeline(steps: d.timeline),
          ),

          SectionCard(
            title: 'Item',
            icon: Icons.checkroom_outlined,
            margin: gap,
            trailing: BookingStatusBadge(status: b.displayStatus()),
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
                const ContactShopButton(outlined: true),
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

/// Vertical timeline. Reached steps have a filled maroon check and their
/// date; later steps an empty circle and "Not yet".
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Icon(
                        steps[i].done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: steps[i].done
                            ? AppColors.maroon
                            : theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      // Line down to the next step.
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i + 1].done
                                ? AppColors.maroon
                                : theme.dividerColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: TextStyle(
                            fontWeight: steps[i].done
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          steps[i].done
                              ? Formatters.dateTime(steps[i].date!)
                              : 'Not yet',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
