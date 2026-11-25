// A password field with a show / hide toggle, for the "Add staff" and
// "Reset password" sheets. The eye button is a 48 px target with a tooltip
// that says what it will do ("Show password" / "Hide password"), so it is
// clear for screen readers too (H6).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

/// A validated password field with show / hide.
class StaffPasswordField extends StatefulWidget {
  /// Creates the field.
  const StaffPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.helperText,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  /// Holds the typed password.
  final TextEditingController controller;

  /// e.g. "Password *".
  final String label;

  /// Checks the value (StaffPassword.validate or validateConfirm).
  final FormFieldValidator<String> validator;

  /// e.g. StaffPassword.helper.
  final String? helperText;

  /// False while saving.
  final bool enabled;

  /// Keyboard action (next field, or done on the last one).
  final TextInputAction textInputAction;

  /// Called on the keyboard action.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<StaffPasswordField> createState() => _StaffPasswordFieldState();
}

class _StaffPasswordFieldState extends State<StaffPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide password' : 'Show password',
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator: widget.validator,
    );
  }
}
