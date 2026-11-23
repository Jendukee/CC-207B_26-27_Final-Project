// Login screen: email + password sign in with validation.
//
// - `from`: where to return after sign in (set by AuthGuard when a guest
//   opens a protected route, e.g. Reserve or My Bookings).
// - `staffMode`: opened from the "Staff sign in" link on the guest
//   Profile tab. Same form, but a non-staff account gets a notice.
// After sign in the user goes to `from`, else their role's home
// (customer -> Browse, staff/owner -> Dashboard).
//
// OWNER: team lead.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/auth_guard.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/features/auth/services/auth_service.dart';

/// Email/password sign-in form.
class LoginScreen extends StatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key, this.from, this.staffMode = false});

  /// Location to return to after sign in.
  final String? from;

  /// True when opened via "Staff sign in".
  final bool staffMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the form, signs in, then navigates to `from` or home.
  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    // Capture before the await: the guard may replace this screen.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final user = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (widget.staffMode && !(user?.role.isStaff ?? false)) {
        messenger.showSnackBar(const SnackBar(
          content: Text('This account does not have staff access. '
              'You are signed in as a customer.'),
        ));
      }
      router.go(AuthGuard.safeFrom(widget.from) ?? AuthGuard.homeFor(user));
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthService.friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.staffMode ? 'Staff sign in' : 'Sign in';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.staffMode
                          ? 'Sign in with your Orange 150 staff account.'
                          : 'Sign in to reserve and see your bookings.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Password'),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(title),
                    ),
                    const SizedBox(height: 12),
                    if (!widget.staffMode)
                      TextButton(
                        onPressed: () => context.goNamed(
                          RouteNames.register,
                          queryParameters: {
                            if (widget.from != null) 'from': widget.from!,
                          },
                        ),
                        child: const Text('No account yet? Create one'),
                      ),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.browse),
                      child: const Text('Continue browsing as guest'),
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

/// Inline error message with an icon (not color alone).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.deepRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );
  }
}
