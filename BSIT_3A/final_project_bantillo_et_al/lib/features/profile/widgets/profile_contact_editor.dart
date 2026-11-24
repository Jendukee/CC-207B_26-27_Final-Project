import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';

/// Opens a validated contact editor and returns the edits if saved.
Future<ProfileContactUpdate?> showProfileContactEditor(
  BuildContext context, {
  required String fullName,
  String? phone,
}) {
  return showDialog<ProfileContactUpdate>(
    context: context,
    builder: (_) => _ProfileContactEditor(fullName: fullName, phone: phone),
  );
}

class _ProfileContactEditor extends StatefulWidget {
  const _ProfileContactEditor({required this.fullName, this.phone});

  final String fullName;
  final String? phone;

  @override
  State<_ProfileContactEditor> createState() => _ProfileContactEditorState();
}

class _ProfileContactEditorState extends State<_ProfileContactEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    Navigator.of(context).pop(
      ProfileContactUpdate(
        fullName: _nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit contact details'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) =>
                Validators.required(value, fieldName: 'Full name'),
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number (optional)',
            ),
            validator: (value) => Validators.phone(value, isRequired: false),
          ),
        ],
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
