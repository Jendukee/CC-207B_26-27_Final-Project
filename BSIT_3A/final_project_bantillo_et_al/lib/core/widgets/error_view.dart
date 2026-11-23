// Error message with a Retry button. Use whenever a Supabase call or
// edge function call fails, so users always have a way to try again.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Shows [message] and a Retry button that calls [onRetry].
class ErrorView extends StatelessWidget {
  /// Creates an error view.
  const ErrorView({super.key, required this.message, required this.onRetry});

  /// User-friendly explanation (no stack traces).
  final String message;

  /// Re-runs the failed operation.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.deepRed),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
