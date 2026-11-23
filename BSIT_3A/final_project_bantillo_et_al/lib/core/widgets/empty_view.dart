// Friendly "nothing here yet" message with an optional action button.
// Use for empty lists (no bookings, no search results, etc.).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Shown when a list or search returns no results.
class EmptyView extends StatelessWidget {
  /// Creates an empty-state view.
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Explains why it is empty and what to do next.
  final String message;

  /// Decorative icon above the message.
  final IconData icon;

  /// Optional button text, e.g. "Browse gowns".
  final String? actionLabel;

  /// Called when the optional button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
