// Reservation step 3: confirm the rental summary and accept the agreement.
//
// UI audit changes: friendly errors with Retry (#12), shared date and peso
// formats (#23), and a line under the disabled Submit button that says
// why it is disabled; the button no longer looks like a payment (#25).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Review the reservation and submit it as a pending booking.
class ReserveReviewScreen extends StatefulWidget {
  const ReserveReviewScreen({super.key, required this.itemId, this.draft});

  final String itemId;
  final ReservationDraft? draft;

  @override
  State<ReserveReviewScreen> createState() => _ReserveReviewScreenState();
}

class _ReserveReviewScreenState extends State<ReserveReviewScreen> {
  static const String _termsVersion = 'orange150-rental-1.0';

  final ReservationService _service = ReservationService();
  late Future<Item> _itemFuture;
  PaymentOption _paymentOption = PaymentOption.full;
  bool _acceptedTerms = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _itemFuture = _service.getItem(widget.itemId);
  }

  Future<void> _submit(ReservationDraft draft) async {
    if (!_acceptedTerms || _submitting) return;
    setState(() => _submitting = true);
    try {
      final booking = await _service.submitReservation(
        itemId: widget.itemId,
        eventDate: draft.eventDate,
        paymentOption: _paymentOption,
        measurementsSnapshot: draft.measurements,
        termsVersion: _termsVersion,
      );
      if (!mounted) return;
      context.goNamed(
        RouteNames.bookingConfirmation,
        pathParameters: {'bookingId': booking.id},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // create_reservation's own messages (e.g. "These dates were just
      // booked...") are shown as-is; anything else gets a plain message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'Could not submit your reservation. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    if (draft == null || draft.itemId != widget.itemId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review & Contract')),
        body: _MissingDraft(
          onRestart: () => context.goNamed(
            RouteNames.reserveDates,
            pathParameters: {'itemId': widget.itemId},
          ),
        ),
      );
    }

    final pickupDate = draft.eventDate.subtract(const Duration(days: 1));
    final returnDate = draft.eventDate.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Contract')),
      body: FutureBuilder<Item>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: friendlyErrorMessage(
                snapshot.error!,
                fallback:
                    'Could not load the reservation details. '
                    'Please try again.',
              ),
              onRetry: () =>
                  setState(() => _itemFuture = _service.getItem(widget.itemId)),
            );
          }
          final item = snapshot.requireData;
          return Column(
            children: [
              const ReservationStepIndicator(step: 3),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Reservation summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: 'Pickup',
                              value: Formatters.date(pickupDate),
                            ),
                            _SummaryRow(
                              label: 'Event',
                              value: Formatters.date(draft.eventDate),
                            ),
                            _SummaryRow(
                              label: 'Return',
                              value: Formatters.date(returnDate),
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Rental total',
                              value: Formatters.peso(item.price),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Payment plan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    RadioGroup<PaymentOption>(
                      groupValue: _paymentOption,
                      onChanged: (value) {
                        if (!_submitting && value != null) {
                          setState(() => _paymentOption = value);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<PaymentOption>(
                            contentPadding: EdgeInsets.zero,
                            value: PaymentOption.full,
                            title: Text(PaymentOption.full.label),
                            subtitle: Text(
                              '${Formatters.peso(item.price)} planned',
                            ),
                          ),
                          RadioListTile<PaymentOption>(
                            contentPadding: EdgeInsets.zero,
                            value: PaymentOption.half,
                            title: Text(PaymentOption.half.label),
                            subtitle: Text(
                              '${Formatters.peso(item.price / 2)} planned as the down payment',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Payment is not collected in the app. The shop will '
                      'confirm your reservation and payment arrangements.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Rental agreement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'By submitting, you confirm that the selected item '
                          'and event dates are correct, agree to collect the '
                          'item on the pickup date and return it on the return '
                          'date, and agree to follow the shop’s care and return '
                          'instructions. Your selected payment plan and '
                          'measurement snapshot will be attached to this '
                          'reservation. This request is pending until the shop '
                          'confirms it; submitting does not process a payment. '
                          'Pay within 48 hours (and before the pickup day) or '
                          'the request expires.',
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedTerms,
                      onChanged: _submitting
                          ? null
                          : (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                      title: const Text(
                        'I have read and agree to the rental agreement.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // UI audit #25: say WHY the button is disabled.
                      if (!_acceptedTerms)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Tick "I have read and agree to the rental '
                            'agreement" to submit.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _acceptedTerms && !_submitting
                              ? () => _submit(draft)
                              : null,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              // No amount on the button: nothing is paid
                              // in the app, it only sends the request.
                              : const Text('Submit reservation request'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _MissingDraft extends StatelessWidget {
  const _MissingDraft({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Complete the date and measurement steps before review.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRestart,
            child: const Text('Start reservation'),
          ),
        ],
      ),
    ),
  );
}
