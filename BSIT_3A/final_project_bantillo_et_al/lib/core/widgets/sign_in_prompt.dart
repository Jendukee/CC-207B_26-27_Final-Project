// "Please sign in" card for guests. Used where a screen is visible to
// guests but its content needs an account (e.g. the guest Profile tab).
// Navigates by route name only, so any feature can use it.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';

/// Sign in / Create account buttons, plus an optional "Staff sign in" link.
class SignInPrompt extends StatelessWidget {
  /// Creates the prompt.
  const SignInPrompt({
    super.key,
    required this.message,
    this.from,
    this.showStaffLink = false,
  });

  /// Why the user should sign in.
  final String message;

  /// Location to come back to after signing in.
  final String? from;

  /// Shows the "Staff sign in" entry point (guest Profile screen).
  final bool showStaffLink;

  @override
  Widget build(BuildContext context) {
    final query = <String, String>{'from': ?from};
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle_outlined,
                  size: 72, color: AppColors.gold),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    context.goNamed(RouteNames.login, queryParameters: query),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.register,
                    queryParameters: query),
                child: const Text('Create an account'),
              ),
              if (showStaffLink) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.goNamed(
                    RouteNames.login,
                    queryParameters: {'staff': '1'},
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Staff sign in'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
