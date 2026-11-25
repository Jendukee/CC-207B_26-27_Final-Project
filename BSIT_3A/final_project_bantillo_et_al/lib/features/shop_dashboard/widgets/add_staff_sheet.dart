// The "Add staff" bottom sheet (More -> Staff accounts, owner only). The
// owner creates the staff login directly; staff do not register first.
//
//   Add staff
//   [ Full name *              ]
//   [ Email *                  ]   email keyboard
//   [ Mobile number (optional) ]   shared PhoneFormField
//   [ Password *          (eye)]   "At least 8 characters with a letter
//   [ Confirm password *  (eye)]    and a number"
//   [ Create staff account     ]   spinner while saving
//
// * Every field is checked before sending (StaffName, StaffEmail,
//   Validators.phone, StaffPassword) (H5 error prevention).
// * A server error (e.g. "An account with this email already exists.")
//   shows inside the sheet, which stays open so the owner can fix it (H9).
// * On success the sheet closes and returns the new account's name and
//   email to the screen (for the "Staff account created" dialog).
//
// Display only: the screen passes [onSubmit], which returns null on
// success or the error text.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/staff_password_field.dart';

/// What the owner typed for a new staff login.
typedef NewStaff = ({
  String fullName,
  String email,
  String? phone,
  String password,
});

/// Opens the sheet. Completes with the created account, or null when it was
/// closed without creating one.
Future<NewStaff?> showAddStaffSheet(
  BuildContext context, {
  required Future<String?> Function(NewStaff staff) onSubmit,
}) {
  return showModalBottomSheet<NewStaff>(
    context: context,
    isScrollControlled: true, // moves up with the keyboard
    showDragHandle: true,
    builder: (_) => AddStaffSheet(onSubmit: onSubmit),
  );
}

/// The sheet's content.
class AddStaffSheet extends StatefulWidget {
  /// Creates it.
  const AddStaffSheet({super.key, required this.onSubmit});

  /// Creates the login; returns null on success or the error text.
  final Future<String?> Function(NewStaff staff) onSubmit;

  @override
  State<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _sending = false;

  /// Error from the server, shown above the button.
  String? _serverError;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    final staff = (
      fullName: StaffName.normalize(_name.text),
      email: StaffEmail.normalize(_email.text),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      password: _password.text,
    );
    setState(() => _sending = true);
    final error = await widget.onSubmit(staff);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(staff);
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
      // Keeps the fields and button above the keyboard.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('Add staff', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a sign-in for a staff member. They can then use '
                  'Staff sign in with this email and password.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !_sending,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: StaffName.validate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  enabled: !_sending,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: StaffEmail.validate,
                ),
                const SizedBox(height: 12),
                PhoneFormField(controller: _phone, enabled: !_sending),
                const SizedBox(height: 12),
                StaffPasswordField(
                  controller: _password,
                  label: 'Password *',
                  helperText: StaffPassword.helper,
                  enabled: !_sending,
                  validator: StaffPassword.validate,
                ),
                const SizedBox(height: 12),
                StaffPasswordField(
                  controller: _confirm,
                  label: 'Confirm password *',
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
                            semanticsLabel: 'Creating',
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(
                    _sending ? 'Creating...' : 'Create staff account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
