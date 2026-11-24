// Register screen: creates a customer account with validation.
//
// Fields: full name, email, mobile (optional, PH format), password,
// confirm password, and a privacy consent checkbox that MUST be ticked
// (Data Privacy Act of 2012 / RA 10173). The consent time is saved to
// profiles.privacy_consent_at by the handle_new_user() trigger.
//
// OWNER: team lead.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/phone_form_field.dart';
import 'package:orange150_rental/features/auth/services/auth_service.dart';

/// Customer registration form.
class RegisterScreen extends StatefulWidget {
  /// Creates the register screen.
  const RegisterScreen({super.key, this.from});

  /// Location to return to after the account is created.
  final String? from;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _consent = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Validates every field (including consent) and creates the account.
  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final router = GoRouter.of(context);

    try {
      final result = await _authService.register(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        privacyConsent: _consent,
      );
      if (!mounted) return;
      if (result == RegisterResult.needsEmailConfirmation) {
        await _showConfirmEmailDialog();
        router.goNamed(
          RouteNames.login,
          queryParameters: {if (widget.from != null) 'from': widget.from!},
        );
      } else {
        router.go(AuthGuard.safeFrom(widget.from) ?? RoutePaths.customerHome);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthService.friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Tells the user to confirm their email before signing in.
  Future<void> _showConfirmEmailDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check your email'),
        content: Text(
          'We sent a confirmation link to ${_emailController.text.trim()}. '
          'Open it, then come back and sign in.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Short privacy notice shown from the consent checkbox.
  void _showPrivacyNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy notice'),
        content: const SingleChildScrollView(
          child: Text(
            'Orange 150 collects your name, email, mobile number and body '
            'measurements only to process your gown or suit rentals and to '
            'contact you about them. Your data is stored securely, is never '
            'sold, and is only visible to you and shop staff. You can update '
            'it or request deletion from your Profile at any time, in line '
            'with the Data Privacy Act of 2012 (RA 10173).',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      // UI audit #26: errors show once the user has touched the field.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Full name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      // UI audit #26: errors show once the user has touched the field.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    // UI audit #2: the shared phone field (digits only,
                    // 11 max, 09XXXXXXXXX) instead of a free text field.
                    PhoneFormField(
                      controller: _phoneController,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      // UI audit #26: errors show once the user has touched the field.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        helperText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      // UI audit #26: errors show once the user has touched the field.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password *',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      // The last field submits the form (UI audit #26).
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _ConsentField(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v),
                      onReadNotice: _showPrivacyNotice,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.deepRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.deepRed),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.goNamed(
                        RouteNames.login,
                        queryParameters: {
                          if (widget.from != null) 'from': widget.from!,
                        },
                      ),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Required privacy consent checkbox, validated as part of the Form.
class _ConsentField extends StatelessWidget {
  const _ConsentField({
    required this.value,
    required this.onChanged,
    required this.onReadNotice,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onReadNotice;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator: (_) => value
          ? null
          : 'Please agree to the privacy notice to create an account.',
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: value,
            onChanged: (checked) {
              onChanged(checked ?? false);
              field.didChange(checked ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I agree that Orange 150 may store and use my personal data '
              'and measurements to process my rentals.',
            ),
          ),
          TextButton(
            onPressed: onReadNotice,
            child: const Text('Read the privacy notice'),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                field.errorText!,
                style: const TextStyle(color: AppColors.deepRed, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
