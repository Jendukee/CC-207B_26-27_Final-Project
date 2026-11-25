// The "Reset password" bottom sheet for one staff login (owner only):
// a new password and its confirmation, each with show / hide, and a
// "Set new password" button with a spinner. Same password rule as "Add
// staff" (StaffPassword). A server error stays in the sheet (H9); on
// success the sheet closes and returns true.
//
// Display only: the screen passes [onSubmit], which returns null on
// success or the error text.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/staff_password_field.dart';

/// Opens the sheet for [name]. Completes with true when the password was
/// changed.
Future<bool?> showResetPasswordSheet(
  BuildContext context, {
  required String name,
  required Future<String?> Function(String password) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ResetPasswordSheet(name: name, onSubmit: onSubmit),
  );
}

/// The sheet's content.
class ResetPasswordSheet extends StatefulWidget {
  /// Creates it.
  const ResetPasswordSheet({
    super.key,
    required this.name,
    required this.onSubmit,
  });

  /// Whose password, e.g. "Pearl Batumbakal".
  final String name;

  /// Sets the password; returns null on success or the error text.
  final Future<String?> Function(String password) onSubmit;

  @override
  State<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _sending = false;
  String? _serverError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final error = await widget.onSubmit(_password.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _serverError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Reset password',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a new password for ${widget.name}, then share it with '
                'them privately.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              StaffPasswordField(
                controller: _password,
                label: 'New password *',
                helperText: StaffPassword.helper,
                enabled: !_sending,
                validator: StaffPassword.validate,
              ),
              const SizedBox(height: 12),
              StaffPasswordField(
                controller: _confirm,
                label: 'Confirm new password *',
                enabled: !_sending,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) =>
                    StaffPassword.validateConfirm(value, _password.text),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _serverError!,
                    style: const TextStyle(color: AppColors.deepRed),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Saving',
                        ),
                      )
                    : const Icon(Icons.key),
                label: Text(_sending ? 'Saving...' : 'Set new password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
