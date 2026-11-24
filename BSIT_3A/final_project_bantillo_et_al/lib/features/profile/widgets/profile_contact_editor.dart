// Dialog to edit the customer's name, mobile number and (optional) address.
//
// * UI audit #3: the mobile number uses the shared PhoneFormField (digits
//   only, 11 max, 09XXXXXXXXX). An older saved number such as
//   "0917 123 4567" is cleaned up when the dialog opens.
// * Phase 2: optional address (profiles.address, migration 0011), used to
//   pre-fill the checkout.
// * UI audit #26: required field marked with *, errors shown as the user
//   types, and the last field's Done key saves.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';

/// Opens a validated contact editor and returns the edits if saved.
Future<ProfileContactUpdate?> showProfileContactEditor(
  BuildContext context, {
  required String fullName,
  String? phone,
  String? address,
}) {
  return showDialog<ProfileContactUpdate>(
    context: context,
    builder: (_) => _ProfileContactEditor(
      fullName: fullName,
      phone: phone,
      address: address,
    ),
  );
}

class _ProfileContactEditor extends StatefulWidget {
  const _ProfileContactEditor({
    required this.fullName,
    this.phone,
    this.address,
  });

  final String fullName;
  final String? phone;
  final String? address;

  @override
  State<_ProfileContactEditor> createState() => _ProfileContactEditorState();
}

class _ProfileContactEditorState extends State<_ProfileContactEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    // Clean up older formats ("+63 917 ...") so the field starts valid;
    // a number that cannot be fixed is kept so the user can correct it.
    _phoneController = TextEditingController(
      text: Validators.normalizePhone(widget.phone) ?? widget.phone ?? '',
    );
    _addressController = TextEditingController(text: widget.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.of(context).pop(
      ProfileContactUpdate(
        fullName: _nameController.text.trim(),
        phone: orNull(_phoneController),
        address: orNull(_addressController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit contact details'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Full name *'),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Full name'),
            ),
            PhoneFormField(controller: _phoneController),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.fullStreetAddress],
              maxLength: 200,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                helperText: 'Pre-fills your checkout, e.g. Jaro, Iloilo City',
              ),
            ),
          ],
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
