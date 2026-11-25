// The ONE mobile number field used everywhere in the app (UI audit,
// finding #1-#3), so every phone input behaves the same:
//   * digits only, at most 11 (Validators.phoneFormatters)
//   * phone keyboard and telephone autofill
//   * helper "Format: 09XXXXXXXXX"
//   * inline error after the user touches the field (Validators.phone)
//
// Example:
//   PhoneFormField(controller: _phoneController)              // optional
//   PhoneFormField(controller: _phoneController, isRequired: true)
//
// Shop settings: optional [labelText] (e.g. "GCash number *") and
// [readOnly] (staff viewing the owner's settings). Left out, the field is
// exactly as before.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/validators.dart';

/// A validated Philippine mobile number field.
class PhoneFormField extends StatelessWidget {
  /// Creates the field.
  const PhoneFormField({
    super.key,
    required this.controller,
    this.isRequired = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.labelText,
    this.readOnly = false,
    this.onChanged,
  });

  /// Custom label; null = "Mobile number *" / "Mobile number (optional)".
  final String? labelText;

  /// Shows the value without letting it be edited (still readable and
  /// selectable, unlike a disabled field).
  final bool readOnly;

  /// Called on every change (e.g. to track unsaved edits).
  final ValueChanged<String>? onChanged;

  /// Holds the typed number.
  final TextEditingController controller;

  /// When false, the field may be left empty.
  final bool isRequired;

  /// False while the form is saving.
  final bool enabled;

  /// Keyboard action button (next field, or done on the last field).
  final TextInputAction textInputAction;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      inputFormatters: Validators.phoneFormatters,
      autofillHints: const [AutofillHints.telephoneNumber],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        // "*" marks required fields; optional ones say so.
        labelText:
            labelText ??
            (isRequired ? 'Mobile number *' : 'Mobile number (optional)'),
        helperText: Validators.phoneHelperText,
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
      validator: (value) => Validators.phone(value, isRequired: isRequired),
    );
  }
}
