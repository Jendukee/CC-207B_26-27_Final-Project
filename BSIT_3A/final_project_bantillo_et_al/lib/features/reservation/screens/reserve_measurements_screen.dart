// Reservation step 2: collect optional fit measurements with customer consent.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';

/// Confirm or enter the customer's body measurements.
class ReserveMeasurementsScreen extends StatefulWidget {
  const ReserveMeasurementsScreen({
    super.key,
    required this.itemId,
    this.draft,
  });

  final String itemId;
  final ReservationDraft? draft;

  @override
  State<ReserveMeasurementsScreen> createState() =>
      _ReserveMeasurementsScreenState();
}

class _ReserveMeasurementsScreenState extends State<ReserveMeasurementsScreen> {
  static const Map<String, (String, double, double)> _measurementFields = {
    'chest': ('Chest', 10, 80),
    'waist': ('Waist', 10, 80),
    'hips': ('Hips', 10, 80),
    'shoulder': ('Shoulder', 6, 35),
    'height': ('Height', 24, 96),
    'inseam': ('Inseam', 8, 45),
  };

  final ReservationService _service = ReservationService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    for (final field in _measurementFields.keys) field: TextEditingController(),
  };
  final TextEditingController _notesController = TextEditingController();
  late final Future<Map<String, dynamic>?> _savedMeasurements;
  bool _consent = false;
  bool _saving = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _savedMeasurements = _service.loadSavedMeasurements();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers(Map<String, dynamic>? saved) {
    if (_controllersInitialized) return;
    for (final field in _measurementFields.keys) {
      final value = saved?[field];
      if (value != null) _controllers[field]!.text = value.toString();
    }
    _notesController.text = saved?['notes'] as String? ?? '';
    // Saved measurements were shared with consent before, so keep it ticked.
    _consent = saved?['consent_at'] != null;
    _controllersInitialized = true;
  }

  /// True when at least one measurement or the notes field is filled in.
  bool get _hasAnyValue =>
      _controllers.values.any((c) => c.text.trim().isNotEmpty) ||
      _notesController.text.trim().isNotEmpty;

  /// Opens the review step with [measurements] attached to the draft.
  void _openReview(Map<String, dynamic> measurements) {
    context.pushNamed(
      RouteNames.reserveReview,
      pathParameters: {'itemId': widget.itemId},
      extra: widget.draft!.withMeasurements(measurements),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    // UI audit #7: measurements are optional. With every field blank the
    // customer continues WITHOUT sharing (no consent needed, nothing saved).
    if (!_hasAnyValue) {
      _openReview(const {});
      return;
    }

    // Consent is only needed when something will actually be shared.
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tick the consent box to share the measurements you entered, '
            'or clear the fields to continue without them.',
          ),
        ),
      );
      return;
    }

    final measurements = <String, dynamic>{
      for (final field in _measurementFields.keys)
        field: double.tryParse(_controllers[field]!.text.trim()),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    setState(() => _saving = true);
    try {
      await _service.saveMeasurements(measurements);
      if (!mounted) return;
      // UI audit #6: stop the spinner BEFORE moving on. Before, _saving
      // stayed true, so pressing Back from Review left this button
      // disabled and spinning for good.
      setState(() => _saving = false);
      _openReview(measurements);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'Could not save your measurements. Please try again.',
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
        appBar: AppBar(title: const Text('Your Measurements')),
        body: _MissingDraft(
          onRestart: () => context.goNamed(
            RouteNames.reserveDates,
            pathParameters: {'itemId': widget.itemId},
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Measurements')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _savedMeasurements,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load saved measurements: ${snapshot.error}',
                ),
              ),
            );
          }
          _initializeControllers(snapshot.data);
          return Column(
            children: [
              const ReservationStepIndicator(step: 2),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Measurements (inches)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These are optional and help the shop prepare your outfit. '
                        'Leave a field blank if you do not know it.',
                      ),
                      const SizedBox(height: 20),
                      for (final entry in _measurementFields.entries) ...[
                        TextFormField(
                          controller: _controllers[entry.key],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '${entry.value.$1} (optional)',
                            suffixText: 'in',
                          ),
                          validator: (value) => Validators.numberRange(
                            value,
                            min: entry.value.$2,
                            max: entry.value.$3,
                            fieldName: entry.value.$1,
                            isRequired: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _notesController,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Fitting notes (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _consent,
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _consent = value ?? false),
                        title: const Text(
                          'I consent to sharing these measurements with the shop.',
                        ),
                        subtitle: const Text(
                          'Only needed if you entered measurements. They '
                          'will be saved to your account for future '
                          'reservations.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _continue,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue to review'),
                    ),
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
          const Text('Choose an event date before entering measurements.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRestart,
            child: const Text('Choose a date'),
          ),
        ],
      ),
    ),
  );
}
