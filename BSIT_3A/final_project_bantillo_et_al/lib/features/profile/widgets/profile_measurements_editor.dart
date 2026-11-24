import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';

/// Opens a validated measurement editor and returns the edits if saved.
Future<ProfileMeasurements?> showProfileMeasurementsEditor(
  BuildContext context, {
  ProfileMeasurements? initial,
}) {
  return showDialog<ProfileMeasurements>(
    context: context,
    builder: (_) => _ProfileMeasurementsEditor(initial: initial),
  );
}

class _ProfileMeasurementsEditor extends StatefulWidget {
  const _ProfileMeasurementsEditor({this.initial});

  final ProfileMeasurements? initial;

  @override
  State<_ProfileMeasurementsEditor> createState() =>
      _ProfileMeasurementsEditorState();
}

class _ProfileMeasurementsEditorState
    extends State<_ProfileMeasurementsEditor> {
  static const Map<String, (String, double, double)> _fields = {
    'chest': ('Chest', 10, 80),
    'waist': ('Waist', 10, 80),
    'hips': ('Hips', 10, 80),
    'shoulder': ('Shoulder', 6, 35),
    'height': ('Height', 24, 96),
    'inseam': ('Inseam', 8, 45),
  };

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final TextEditingController _notesController;
  bool _consent = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final values = widget.initial?.toMap() ?? const <String, dynamic>{};
    _controllers = {
      for (final field in _fields.keys)
        field: TextEditingController(text: values[field]?.toString() ?? ''),
    };
    _notesController = TextEditingController(text: widget.initial?.notes ?? '');
    _consent = widget.initial?.consentAt != null;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final values = {
      for (final field in _fields.keys)
        field: double.tryParse(_controllers[field]!.text.trim()),
    };
    if (!values.values.any((value) => value != null)) {
      setState(() => _formError = 'Enter at least one measurement to save.');
      return;
    }
    if (!_consent) {
      setState(() => _formError = 'Consent is required to save measurements.');
      return;
    }

    Navigator.of(context).pop(
      ProfileMeasurements(
        chest: values['chest'],
        waist: values['waist'],
        hips: values['hips'],
        shoulder: values['shoulder'],
        height: values['height'],
        inseam: values['inseam'],
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Saved measurements'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter measurements in inches. All fields are optional, '
                'but at least one value is needed to save.',
              ),
              const SizedBox(height: 12),
              for (final entry in _fields.entries) ...[
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
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _notesController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: (value) => setState(() {
                  _consent = value ?? false;
                  _formError = null;
                }),
                title: const Text(
                  'I consent to sharing these measurements with the shop.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_formError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
