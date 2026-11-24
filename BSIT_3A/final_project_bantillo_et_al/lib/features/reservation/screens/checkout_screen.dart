// Reservation checkout: ONE checkout-style page instead of separate step
// screens (customer redesign, Phase 1). Opened from Item details with the
// chosen event date: /reserve/:itemId/checkout?date=yyyy-MM-dd
//
//   Card 1 Contact details  full name, mobile (pre-filled from Profile,
//                           saved back to it), address (pre-filled from
//                           profiles.address; saved to the profile only
//                           if "Save this address to my profile" is ticked)
//   Card 2 Item             photo, name, size, price
//   Card 3 Rental schedule  pick-up / event / return, optional preferred
//                           fitting date
//   Card 4 Measurements     optional, pre-filled, collapsible
//   Card 5 Payment option   50% reservation fee or full payment (radio
//                           cards with amounts) and Cash / GCash / Bank
//   Card 6 Rental agreement the e-contract from the shop's paper form
//                           (Phase 2, RentalAgreementCard): read-only form,
//                           accessories, terms and the optional fields
//   Card 7 Sign and submit  LAST card (customer redesign 2): the typed
//                           signature, the agreement checkbox and the
//                           signing time, right above the sticky bar, so
//                           everything is read before signing (H6, H5)
//   Sticky bar              "Total ₱X · Pay now ₱Y" + "Submit request",
//                           disabled with a reason until the agreement is
//                           signed; tapping the reason scrolls to Card 7
//
// Submitting calls create_reservation (0011), which stores the address,
// Facebook account, fitting date, note, payment method, typed signature
// and the exact terms shown (terms_snapshot), then opens the Request
// submitted screen.
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
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/rental_agreement_card.dart';
import 'package:orange150_rental/features/reservation/widgets/sign_and_submit_fields.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

/// Everything the checkout needs, loaded together.
class _CheckoutData {
  const _CheckoutData({
    required this.item,
    required this.available,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.measurements,
  });

  final Item item;

  /// False when the chosen dates were booked meanwhile.
  final bool available;
  final String fullName;
  final String phone;

  /// profiles.address ('' when not saved).
  final String address;
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

  /// The "Sign and submit" card, scrolled to from the sticky bar.
  final GlobalKey _signCardKey = GlobalKey(debugLabel: 'signAndSubmit');

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

  // Card 1: save the address to the profile? (only when ticked)
  bool _saveAddress = false;
  String _profileAddress = '';

  // Card 6: e-contract fields and signature.
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _shoeSize = TextEditingController();
  final TextEditingController _sleevesSize = TextEditingController();
  final TextEditingController _signature = TextEditingController();
  bool _agreed = false;

  /// When the signature became valid (shown as "Signed on ..."); null
  /// while not signed.
  DateTime? _signedAt;

  bool _submitting = false;
  bool _prefilled = false;

  /// Signed = the typed name matches Card 1's full name AND the box is
  /// ticked. Submit request stays disabled until then.
  bool get _signed =>
      _agreed && AgreementRules.nameMatches(_signature.text, _name.text);

  /// Re-checks the signature after any change and keeps [_signedAt]: set
  /// when it becomes valid, cleared when it becomes invalid again.
  void _onSignatureChanged() {
    setState(() {
      if (_signed) {
        _signedAt ??= DateTime.now();
      } else {
        _signedAt = null;
      }
    });
  }

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
      _facebook,
      _note,
      _shoeSize,
      _sleevesSize,
      _signature,
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
    final contact = results[2]! as CheckoutContact;
    return _CheckoutData(
      item: results[0]! as Item,
      available: results[1]! as bool,
      fullName: contact.fullName,
      phone: contact.phone,
      address: contact.address,
      measurements: results[3] as Map<String, dynamic>?,
    );
  }

  /// Fills the fields once with the profile values.
  void _prefill(_CheckoutData data) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = data.fullName;
    _phone.text = Validators.normalizePhone(data.phone) ?? data.phone;
    _address.text = data.address;
    _profileAddress = data.address;
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

  /// Everything on the rental agreement, from the other cards.
  AgreementForm _agreementForm(_CheckoutData data) => AgreementForm(
    fullName: _name.text.trim(),
    phone: _phone.text.trim(),
    address: _address.text.trim(),
    facebook: _facebook.text.trim(),
    item: data.item,
    eventDate: widget.eventDate!,
    fittingDate: _fittingDate,
    paymentOption: _option,
    method: _method,
    shoeSize: _shoeSize.text.trim(),
    longSleevesSize: _sleevesSize.text.trim(),
    waist: double.tryParse(_measure['waist']!.text.trim()),
    shoulder: double.tryParse(_measure['shoulder']!.text.trim()),
    adjustments: _measureNotes.text.trim(),
    note: _note.text.trim(),
  );

  Future<void> _submit(_CheckoutData data) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_signed) return; // button is disabled; safety net
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
      // 1. Keep the profile up to date with the contact details used. The
      //    address is saved to the profile only when the box is ticked.
      await _service.saveContact(
        fullName: _name.text,
        phone: _phone.text,
        address: _saveAddress ? _address.text : null,
      );

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

      // Accessory sizes from the agreement travel with the measurements
      // snapshot (the measurements table itself only keeps body sizes).
      final snapshotMeasurements = {
        ...measurements,
        if (_shoeSize.text.trim().isNotEmpty)
          'shoe_size': _shoeSize.text.trim(),
        if (_sleevesSize.text.trim().isNotEmpty)
          'long_sleeves_size': _sleevesSize.text.trim(),
      };

      // 3. The booking with its signed e-contract (create_reservation,
      //    one transaction; it re-checks the signature too).
      final signedAt = _signedAt ?? DateTime.now();
      final form = _agreementForm(data);
      final booking = await _service.submitReservation(
        itemId: widget.itemId,
        eventDate: widget.eventDate!,
        paymentOption: _option,
        measurementsSnapshot: snapshotMeasurements,
        termsVersion: RentalTerms.version,
        // Card 1's name: the database checks the signature against
        // it (0012), not against the profile name.
        fullName: _name.text,
        signedName: _signature.text,
        termsAcknowledgedAt: signedAt,
        termsSnapshot: form.toSnapshot(
          signedName: _signature.text,
          signedAt: signedAt,
        ),
        paymentMethod: _method,
        address: _address.text,
        facebook: _facebook.text,
        fittingDate: _fittingDate,
        notes: _note.text,
      );
      if (!mounted) return;

      // go (not push): Back from "Request submitted" must not return here.
      // The payment method is now saved with the booking (no link value).
      context.goNamed(
        RouteNames.bookingConfirmation,
        pathParameters: {'bookingId': booking.id},
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
          // Customer redesign 2: shared header with the Orange 150 mark (H4).
          appBar: const BrandAppBar(title: 'Checkout'),
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
      message: _signed
          ? null
          : 'Sign the rental agreement (last card): type your full name '
                'and tick the box.',
      // Customer redesign 2: tapping the reason scrolls to "Sign and
      // submit" (H5, H7).
      onMessageTap: _signed ? null : _scrollToSignCard,
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
        onPressed: _signed && !_submitting ? () => _submit(data) : null,
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
      // Customer redesign 2: a Column in a scroll view (not a lazy
      // ListView), so the last card always exists and the sticky bar can
      // scroll to it. The page has only seven cards.
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    // The signature must match this name, so re-check it.
                    onChanged: (_) => _onSignatureChanged(),
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
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                      helperText: 'Barangay and city, e.g. Jaro, Iloilo City',
                    ),
                  ),
                  // Only offered when the address differs from the profile;
                  // the profile changes only if the customer ticks it.
                  if (_address.text.trim() != _profileAddress)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _saveAddress,
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _saveAddress = v ?? false),
                      title: const Text('Save this address to my profile'),
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
                          ButtonSegment(
                            value: method,
                            label: Text(method.label),
                          ),
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

            // Card 6: the e-contract (shop's paper reservation form).
            SectionCard(
              title: 'Rental agreement',
              icon: Icons.assignment_outlined,
              margin: gap,
              child: RentalAgreementCard(
                form: _agreementForm(data),
                facebook: _facebook,
                note: _note,
                shoeSize: _shoeSize,
                longSleevesSize: _sleevesSize,
                enabled: !_submitting,
                // Rebuild so the read-only rows follow the editable fields.
                onChanged: _onSignatureChanged,
              ),
            ),

            // Card 7 (customer redesign 2): the signature comes LAST, after
            // every other card and right above the Submit bar (H6, H5).
            SectionCard(
              key: _signCardKey,
              title: 'Sign and submit',
              icon: Icons.draw_outlined,
              margin: gap,
              child: SignAndSubmitFields(
                fullName: _name.text.trim(),
                signature: _signature,
                agreed: _agreed,
                signedAt: _signedAt,
                enabled: !_submitting,
                onAgreedChanged: (value) {
                  _agreed = value;
                  _onSignatureChanged();
                },
                onChanged: _onSignatureChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scrolls the "Sign and submit" card into view.
  void _scrollToSignCard() {
    final target = _signCardKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
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
