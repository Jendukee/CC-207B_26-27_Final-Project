// More -> Shop settings (/shop/more/settings). Replaces the "coming soon"
// placeholder. The owner edits; staff see the same values read-only.
//
//   1. Shop details   address, contact numbers (1 to 3, add / remove),
//                     GCash number (shared PhoneFormField)
//   2. Shop hours     free text, e.g. "Mon to Sat, 9:00 AM to 6:00 PM"
//   3. Booking rules  payment window (12 / 24 / 48 / 72 hours) and the late
//                     fee per day (₱, money formatter)
//   4. Rental terms   fixed in the app; "View rental terms" shows them
//
// * Loading: a spinner; an error shows the message with Retry (it never
//   edits the built-in defaults by mistake) (H1, H9).
// * Owner: inline errors as they type (ShopSettingsForm, the same rules as
//   update_shop_settings in 0016), a sticky Save bar that is enabled only
//   when something changed, "Shop settings saved" on success, and a
//   "Discard changes?" prompt when leaving with unsaved edits (H3, H5).
// * Staff: a banner "Only the owner can change shop settings." and the
//   same fields read-only, no Save bar (the database refuses staff too).
// * Saved values reach the whole app at once through ShopSettingsService
//   (payment instructions, Contact the shop, the return checklist's late
//   fee, and the payment deadline of NEW requests).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_settings.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/services/shop_settings_service.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/shop_dashboard/models/shop_settings_form.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// The Shop settings screen.
class ShopSettingsScreen extends StatefulWidget {
  /// Creates the screen. [service] and [isOwner] are for tests; the app
  /// uses the shared service and the signed-in role.
  const ShopSettingsScreen({super.key, this.service, this.isOwner});

  /// Settings source (default ShopSettingsService.instance).
  final ShopSettingsService? service;

  /// Overrides the role check (default: signed-in user is the owner).
  final bool? isOwner;

  /// Banner shown to staff.
  static const String ownerOnlyMessage =
      'Only the owner can change shop settings.';

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  late final ShopSettingsService _service =
      widget.service ?? ShopSettingsService.instance;
  late final bool _owner =
      widget.isOwner ?? SessionController.instance.user?.role == UserRole.owner;

  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _gcash = TextEditingController();
  final _hours = TextEditingController();
  final _lateFee = TextEditingController();
  List<TextEditingController> _numbers = [];
  int _window = ShopSettings.defaults.paymentWindowHours;

  /// The values last loaded or saved (null until loaded).
  ShopSettings? _saved;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Every edit re-checks "unsaved changes" (Save button, Back prompt).
    for (final c in [_address, _gcash, _hours, _lateFee]) {
      c.addListener(_onEdited);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [_address, _gcash, _hours, _lateFee, ..._numbers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEdited() => setState(() {});

  /// Loads from the database (not the cached defaults), with Retry.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await _service.fetch();
      if (!mounted) return;
      _fill(settings);
      setState(() => _loading = false);
    } on ShopSettingsException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  /// Puts [settings] into the fields and remembers them as saved.
  void _fill(ShopSettings settings) {
    _saved = settings;
    _address.text = settings.address;
    _gcash.text = settings.gcashNumber;
    _hours.text = settings.shopHours ?? '';
    _lateFee.text = ShopSettingsForm.lateFeeText(settings.lateFeePerDay);
    _window = settings.paymentWindowHours;
    for (final c in _numbers) {
      c.dispose();
    }
    _numbers = [
      for (final n in settings.contactNumbers.take(
        ShopSettingsForm.maxContactNumbers,
      ))
        TextEditingController(text: n)..addListener(_onEdited),
    ];
  }

  /// True when the owner has unsaved edits.
  bool get _dirty {
    final saved = _saved;
    if (!_owner || saved == null) return false;
    return ShopSettingsForm.hasChanges(
      saved: saved,
      address: _address.text,
      contactNumbers: [for (final c in _numbers) c.text],
      gcash: _gcash.text,
      hours: _hours.text,
      window: _window,
      lateFee: _lateFee.text,
    );
  }

  void _addNumber() => setState(
    () => _numbers = [
      ..._numbers,
      TextEditingController()..addListener(_onEdited),
    ],
  );

  void _removeNumber(int index) {
    final removed = _numbers[index];
    setState(() => _numbers = [..._numbers]..removeAt(index));
    // Dispose after the field that used it is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _snack('Please fix the fields marked in red.');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _service.save(
        shopHours: _hours.text.trim().isEmpty ? null : _hours.text.trim(),
        paymentWindowHours: _window,
        lateFeePerDay: ShopSettingsForm.parseLateFee(_lateFee.text),
        address: _address.text.trim(),
        contactNumbers: [for (final c in _numbers) c.text.trim()],
        gcashNumber: _gcash.text.trim(),
      );
      if (!mounted) return;
      setState(() => _fill(saved));
      _snack('Shop settings saved');
    } on ShopSettingsException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Back with unsaved edits: ask first.
  Future<void> _confirmLeave() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your changes to the shop settings are not saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    // Navigator.pop leaves even though PopScope says no.
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: const BrandAppBar(
          title: 'Shop settings',
          backgroundColor: AppColors.maroonDeep, // as on the Dashboard
          showLogo: false, // no hanger mark on staff headers
        ),
        bottomNavigationBar: (_owner && _saved != null && !_loading)
            ? StickyActionBar(
                message: dirty ? 'You have unsaved changes.' : null,
                action: FilledButton.icon(
                  onPressed: (dirty && !_saving) ? _save : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Saving',
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              )
            : null,
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView(message: 'Loading shop settings...');
    if (_loadError != null) {
      return ErrorView(message: _loadError!, onRetry: _load);
    }
    final readOnly = !_owner || _saving;
    final saved = _saved!;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Center(
        child: ConstrainedBox(
          // Readable line length on laptops.
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_owner) const _OwnerOnlyBanner(),
              _shopDetails(readOnly),
              _shopHours(readOnly),
              _bookingRules(readOnly),
              _rentalTerms(),
              if (saved.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Last saved ${Formatters.dateTime(saved.updatedAt!)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Shop details -----------------------------------------------------------

  Widget _shopDetails(bool readOnly) {
    final canAdd =
        !readOnly && _numbers.length < ShopSettingsForm.maxContactNumbers;
    final countError = ShopSettingsForm.validateContactCount(_numbers.length);
    return SectionCard(
      title: 'Shop details',
      icon: Icons.storefront_outlined,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _address,
            readOnly: readOnly,
            minLines: 1,
            maxLines: 3,
            maxLength: readOnly ? null : ShopSettingsForm.maxAddressLength,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Shop address *',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: ShopSettingsForm.validateAddress,
          ),
          const SizedBox(height: 12),
          Text(
            'Contact numbers',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _numbers.length; i++)
            Padding(
              // Keyed by controller so removing one keeps the others' text.
              key: ObjectKey(_numbers[i]),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _numbers[i],
                      label: i == 0
                          ? 'Main contact number *'
                          : 'Contact number ${i + 1} *',
                      readOnly: readOnly,
                      validator: (value) =>
                          ShopSettingsForm.validateContactNumber(
                            value,
                            all: [for (final c in _numbers) c.text],
                            index: i,
                          ),
                    ),
                  ),
                  // At least one number stays.
                  if (!readOnly && _numbers.length > 1)
                    IconButton(
                      tooltip: 'Remove contact number ${i + 1}',
                      onPressed: () => _removeNumber(i),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.deepRed,
                    ),
                ],
              ),
            ),
          if (countError != null)
            Text(countError, style: const TextStyle(color: AppColors.deepRed)),
          if (canAdd)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addNumber,
                icon: const Icon(Icons.add),
                label: const Text('Add contact number'),
              ),
            )
          else if (!readOnly)
            const Text(
              'Up to 3 contact numbers.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 12),
          // Format only (PhoneFormField's own check = validateGcash).
          PhoneFormField(
            controller: _gcash,
            isRequired: true,
            labelText: 'GCash number *',
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }

  // 2. Shop hours -------------------------------------------------------------

  Widget _shopHours(bool readOnly) => SectionCard(
    title: 'Shop hours',
    icon: Icons.schedule,
    margin: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _hours,
      readOnly: readOnly,
      maxLength: readOnly ? null : ShopSettingsForm.maxHoursLength,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Shop hours (optional)',
        helperText: ShopSettingsForm.hoursHelper,
        prefixIcon: Icon(Icons.access_time),
      ),
      validator: ShopSettingsForm.validateHours,
    ),
  );

  // 3. Booking rules ----------------------------------------------------------

  Widget _bookingRules(bool readOnly) => SectionCard(
    title: 'Booking rules',
    icon: Icons.rule,
    margin: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _window,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Payment window *',
            helperText:
                'How long a new request stays open for payment (never past '
                'the pick-up day).',
            helperMaxLines: 3,
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          items: [
            for (final hours in ShopSettingsForm.windowChoicesFor(_window))
              DropdownMenuItem(
                value: hours,
                child: Text(ShopSettingsForm.windowLabel(hours)),
              ),
          ],
          // null = shown but not changeable (staff).
          onChanged: readOnly
              ? null
              : (hours) => setState(() => _window = hours ?? _window),
          validator: ShopSettingsForm.validateWindow,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lateFee,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: ShopSettingsForm.lateFeeFormatters,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Late fee per day *',
            prefixText: '₱ ',
            helperText: 'Pre-filled on the return checklist for each late day.',
            helperMaxLines: 2,
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          validator: ShopSettingsForm.validateLateFee,
        ),
      ],
    ),
  );

  // 4. Rental terms (read-only) -----------------------------------------------

  Widget _rentalTerms() => SectionCard(
    title: 'Rental terms',
    icon: Icons.description_outlined,
    margin: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental terms are fixed in the app. Customers agree to them when '
          'they sign the rental agreement.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _showTerms,
            icon: const Icon(Icons.open_in_new),
            label: const Text('View rental terms'),
          ),
        ),
      ],
    ),
  );

  /// The numbered terms, as customers see them (RentalTerms).
  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental terms'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < RentalTerms.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${i + 1}. ${RentalTerms.items[i]}'),
                ),
              Text(
                'Version ${RentalTerms.version}',
                style: const TextStyle(color: AppColors.textSecondary),
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
}

/// A shared PhoneFormField with its own label and an extra check (e.g. no
/// repeated number), which runs after PhoneFormField's own format check.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.readOnly,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    // FormField wrapper: PhoneFormField shows the format error itself; this
    // adds only the OTHER settings rules (e.g. no repeats) under the field,
    // so a format error is never shown twice.
    return FormField<String>(
      validator: (_) {
        if (Validators.phone(controller.text, isRequired: true) != null) {
          return null;
        }
        return validator(controller.text);
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhoneFormField(
            controller: controller,
            isRequired: true,
            labelText: label,
            readOnly: readOnly,
            onChanged: state.didChange,
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                state.errorText!,
                style: const TextStyle(color: AppColors.deepRed),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Only the owner can change shop settings." on top, for staff.
class _OwnerOnlyBanner extends StatelessWidget {
  const _OwnerOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.goldTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.textPrimary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                ShopSettingsScreen.ownerOnlyMessage,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
