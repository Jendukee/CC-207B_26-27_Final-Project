// Reservation checkout: ONE checkout-style page instead of separate step
// screens (customer redesign, Phase 1). Opened from Item details with the
// chosen event date: /reserve/:itemId/checkout?date=yyyy-MM-dd
//
//   Card 1 Contact details  full name, mobile (pre-filled from Profile,
//                           saved back to it), address
//   Card 2 Item             photo, name, size, price
//   Card 3 Rental schedule  pick-up / event / return, optional preferred
//                           fitting date
//   Card 4 Measurements     optional, pre-filled, collapsible
//   Card 5 Payment option   50% reservation fee or full payment (radio
//                           cards with amounts) and Cash / GCash / Bank
//   Card 6 Rental agreement the shop's terms + agreement checkbox
//                           (becomes the full e-contract in Phase 2)
//   Sticky bar              "Total ₱X · Pay now ₱Y" + "Submit request",
//                           disabled with a reason until the agreement is
//                           accepted
//
// Submitting calls create_reservation (0009) and opens the Request
// submitted screen. Address, fitting date and payment method are collected
// here; they are stored with the booking from Phase 2 (new columns).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/reservation/models/payment_plan.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Everything the checkout needs, loaded together.
class _CheckoutData {
  const _CheckoutData({
    required this.item,
    required this.available,
    required this.fullName,
    required this.phone,
    required this.measurements,
  });

  final Item item;

  /// False when the chosen dates were booked meanwhile.
  final bool available;
  final String fullName;
  final String phone;
  final Map<String, dynamic>? measurements;
}

/// The checkout page.
class CheckoutScreen extends StatefulWidget {
  /// Creates the checkout for [itemId] on [eventDate] (null = bad link).
  const CheckoutScreen({super.key, required this.itemId, this.eventDate});

  /// Path parameter.
  final String itemId;

  /// From the ?date= query parameter.
  final DateTime? eventDate;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Same measurement fields and ranges (inches) as the profile editor.
  static const Map<String, (String, double, double)> _measurementFields = {
    'chest': ('Chest', 10, 80),
    'waist': ('Waist', 10, 80),
    'hips': ('Hips', 10, 80),
    'shoulder': ('Shoulder', 6, 35),
    'height': ('Height', 24, 96),
    'inseam': ('Inseam', 8, 45),
  };

  final ReservationService _service = ReservationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Future<_CheckoutData> _future;

  // Card 1.
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();

  // Card 3.
  DateTime? _fittingDate;

  // Card 4.
  final Map<String, TextEditingController> _measure = {
    for (final key in _measurementFields.keys) key: TextEditingController(),
  };
  final TextEditingController _measureNotes = TextEditingController();
  bool _measureConsent = false;

  // Card 5.
  PaymentOption _option = PaymentOption.half;
  PlannedPaymentMethod _method = PlannedPaymentMethod.gcash;

  // Card 6.
  bool _agreed = false;

  bool _submitting = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _address,
      _measureNotes,
      ..._measure.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<_CheckoutData> _load() async {
    final date = widget.eventDate;
    if (date == null) throw StateError('missing date');
    final results = await Future.wait<Object?>([
      _service.getItem(widget.itemId),
      _service.isItemAvailable(itemId: widget.itemId, eventDate: date),
      _service.loadContact(),
      _service.loadSavedMeasurements(),
    ]);
    final contact = results[2]! as ({String fullName, String phone});
    return _CheckoutData(
      item: results[0]! as Item,
      available: results[1]! as bool,
      fullName: contact.fullName,
      phone: contact.phone,
      measurements: results[3] as Map<String, dynamic>?,
    );
  }

  /// Fills the fields once with the profile values.
  void _prefill(_CheckoutData data) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = data.fullName;
    _phone.text = Validators.normalizePhone(data.phone) ?? data.phone;
    final saved = data.measurements;
    if (saved != null) {
      for (final key in _measurementFields.keys) {
        if (saved[key] != null) _measure[key]!.text = '${saved[key]}';
      }
      _measureNotes.text = saved['notes'] as String? ?? '';
      _measureConsent = saved['consent_at'] != null;
    }
  }

  bool get _hasMeasurements =>
      _measure.values.any((c) => c.text.trim().isNotEmpty) ||
      _measureNotes.text.trim().isNotEmpty;

  /// Preferred fitting date: from today until the day before pick-up.
  Future<void> _pickFittingDate(DateTime pickup) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final last = pickup.subtract(const Duration(days: 1));
    if (last.isBefore(today)) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fittingDate ?? today,
      firstDate: today,
      lastDate: last,
      helpText: 'Preferred fitting date',
    );
    if (picked != null) setState(() => _fittingDate = picked);
  }

  Future<void> _submit(_CheckoutData data) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Check the highlighted fields.')),
      );
      return;
    }
    if (_hasMeasurements && !_measureConsent) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tick the measurement consent box, or clear the measurements.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1. Keep the profile up to date with the contact details used.
      await _service.saveContact(fullName: _name.text, phone: _phone.text);

      // 2. Measurements (optional).
      final measurements = <String, dynamic>{};
      if (_hasMeasurements) {
        measurements.addAll({
          for (final key in _measurementFields.keys)
            key: double.tryParse(_measure[key]!.text.trim()),
          'notes': _measureNotes.text.trim().isEmpty
              ? null
              : _measureNotes.text.trim(),
        });
        await _service.saveMeasurements(measurements);
      }

      // 3. The booking itself (create_reservation, one transaction).
      final booking = await _service.submitReservation(
        itemId: widget.itemId,
        eventDate: widget.eventDate!,
        paymentOption: _option,
        measurementsSnapshot: measurements,
        termsVersion: RentalTerms.version,
      );
      if (!mounted) return;

      // go (not push): Back from "Request submitted" must not return here.
      context.goNamed(
        RouteNames.bookingConfirmation,
        pathParameters: {'bookingId': booking.id},
        queryParameters: {'method': _method.dbValue},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'Could not submit your request. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_CheckoutData>(
      future: _future,
      builder: (context, snapshot) {
        final ready =
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError;
        final data = ready ? snapshot.requireData : null;
        if (data != null) _prefill(data);

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          appBar: AppBar(title: const Text('Checkout')),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when snapshot.hasError => ErrorView(
              message: widget.eventDate == null
                  ? 'Choose an event date on the item page first.'
                  : friendlyErrorMessage(
                      snapshot.error!,
                      fallback:
                          'Could not load the checkout. Please try again.',
                    ),
              onRetry: () => setState(() => _future = _load()),
            ),
            ConnectionState.done => _body(data!, theme),
            _ => const LoadingView(message: 'Preparing your checkout...'),
          },
          bottomNavigationBar: data == null || !data.available
              ? null
              : _bottomBar(data, theme),
        );
      },
    );
  }

  /// Sticky bar: totals on the left, Submit request on the right.
  Widget _bottomBar(_CheckoutData data, ThemeData theme) {
    final total = data.item.price;
    final now = PaymentPlan.dueNow(total, _option);
    return StickyActionBar(
      message: _agreed
          ? null
          : 'Accept the rental agreement (last card) to submit.',
      leading: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${Formatters.peso(total)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Pay now ${Formatters.peso(now)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.maroon,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      action: FilledButton(
        onPressed: _agreed && !_submitting ? () => _submit(data) : null,
        child: _submitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Submit request'),
      ),
    );
  }

  Widget _body(_CheckoutData data, ThemeData theme) {
    final event = widget.eventDate!;
    final pickup = event.subtract(const Duration(days: 1));
    final returnDay = event.add(const Duration(days: 1));
    const gap = EdgeInsets.fromLTRB(8, 0, 8, 8);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const ReservationStepIndicator(
            step: 2,
            labels: ['Date', 'Checkout', 'Submitted'],
          ),
          const SizedBox(height: 8),
          if (!data.available)
            SectionCard(
              margin: gap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'These dates were just booked by someone else. '
                    'Please choose another date.',
                    style: TextStyle(color: AppColors.deepRed),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Choose another date'),
                  ),
                ],
              ),
            ),

          // Card 1: contact details.
          SectionCard(
            title: 'Contact details',
            icon: Icons.person_outline,
            margin: gap,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Full name *'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Full name'),
                ),
                const SizedBox(height: 12),
                PhoneFormField(
                  controller: _phone,
                  isRequired: true,
                  enabled: !_submitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    helperText: 'Barangay and city, e.g. Jaro, Iloilo City',
                  ),
                ),
              ],
            ),
          ),

          // Card 2: item.
          SectionCard(
            title: 'Item',
            icon: Icons.checkroom_outlined,
            margin: gap,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 72,
                    child: data.item.photoUrls.isEmpty
                        ? ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.checkroom),
                          )
                        : Image.network(
                            data.item.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.checkroom),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${data.item.type.label} · Size ${data.item.size}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.peso(data.item.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.maroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card 3: rental schedule.
          SectionCard(
            title: 'Rental schedule',
            icon: Icons.event_outlined,
            margin: gap,
            trailing: TextButton(
              onPressed: _submitting ? null : () => context.pop(),
              child: const Text('Change'),
            ),
            child: Column(
              children: [
                _row('Pick-up', Formatters.date(pickup)),
                _row('Event', Formatters.date(event)),
                _row('Return', Formatters.date(returnDay)),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fittingDate == null
                            ? 'Preferred fitting date (optional)\n'
                                  'To be arranged with the shop'
                            : 'Preferred fitting date\n'
                                  '${Formatters.date(_fittingDate!)}',
                      ),
                    ),
                    if (_fittingDate != null)
                      IconButton(
                        tooltip: 'Remove fitting date',
                        onPressed: () => setState(() => _fittingDate = null),
                        icon: const Icon(Icons.close),
                      ),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => _pickFittingDate(pickup),
                      child: Text(_fittingDate == null ? 'Choose' : 'Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card 4: measurements (collapsible).
          SectionCard(
            margin: gap,
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              leading: const Icon(Icons.straighten, color: AppColors.maroon),
              title: const Text('Measurements (optional)'),
              subtitle: Text(
                _hasMeasurements
                    ? 'Saved measurements will be shared with the shop'
                    : 'Helps the shop prepare your fit',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final entry in _measurementFields.entries) ...[
                  TextFormField(
                    controller: _measure[entry.key],
                    enabled: !_submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: Validators.measurementFormatters,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: entry.value.$1,
                      suffixText: 'in',
                    ),
                    validator: (v) => Validators.numberRange(
                      v,
                      min: entry.value.$2,
                      max: entry.value.$3,
                      fieldName: entry.value.$1,
                      isRequired: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _measureNotes,
                  enabled: !_submitting,
                  maxLength: 500,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Fitting notes (optional)',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _measureConsent,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _measureConsent = v ?? false),
                  title: const Text(
                    'I consent to sharing these measurements with the shop.',
                  ),
                  subtitle: const Text('Only needed if you entered any.'),
                ),
              ],
            ),
          ),

          // Card 5: payment option and method.
          SectionCard(
            title: 'Payment option',
            icon: Icons.payments_outlined,
            margin: gap,
            child: RadioGroup<PaymentOption>(
              groupValue: _option,
              onChanged: (value) {
                if (!_submitting && value != null) {
                  setState(() => _option = value);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _optionCard(
                    PaymentOption.half,
                    '50% reservation fee',
                    'Pay ${Formatters.peso(PaymentPlan.dueNow(data.item.price, PaymentOption.half))} now, '
                        '${Formatters.peso(PaymentPlan.balanceAfter(data.item.price, PaymentOption.half))} at pick-up. '
                        'Non-refundable.',
                  ),
                  const SizedBox(height: 8),
                  _optionCard(
                    PaymentOption.full,
                    'Full payment',
                    'Pay ${Formatters.peso(data.item.price)} now, nothing at pick-up.',
                  ),
                  const SizedBox(height: 16),
                  Text('Payment method', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<PlannedPaymentMethod>(
                    showSelectedIcon: false,
                    segments: [
                      for (final method in PlannedPaymentMethod.values)
                        ButtonSegment(value: method, label: Text(method.label)),
                    ],
                    selected: {_method},
                    onSelectionChanged: _submitting
                        ? null
                        : (s) => setState(() => _method = s.first),
                  ),
                ],
              ),
            ),
          ),

          // Card 6: rental agreement (full e-contract in Phase 2).
          SectionCard(
            title: 'Rental agreement',
            icon: Icons.assignment_outlined,
            margin: gap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < RentalTerms.items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${i + 1}. ${RentalTerms.items[i]}'),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _agreed,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _agreed = v ?? false),
                  title: const Text(
                    'I have read and agree to the rental terms of Orange 150.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A radio "card" for one payment option. The whole card is tappable
  /// and the selected one gets a maroon border (plus the radio dot).
  Widget _optionCard(PaymentOption option, String title, String subtitle) {
    final selected = _option == option;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.maroon : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: RadioListTile<PaymentOption>(
        value: option,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

/// Reads the ?date= query parameter (yyyy-MM-dd); null when missing/bad.
DateTime? parseCheckoutDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}
