// Bottom action bar that stays on screen while the page scrolls (like the
// "Buy now" bar of a shopping app). Put it in Scaffold.bottomNavigationBar.
// Used for: Item details (Ask / Reserve Now), checkout (Total / Submit
// request), record payment and the checklists (staff), so the main action
// is always reachable, above the keyboard and the phone's safe area.
//
// [leading] sits on the left (amounts, a secondary button); [action] is the
// main button and takes the remaining width. [message] is an optional line
// above both, e.g. why the main button is disabled.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// A white bar with a top border, safe-area padding and a main action.
class StickyActionBar extends StatelessWidget {
  /// Creates the bar.
  const StickyActionBar({
    super.key,
    required this.action,
    this.leading,
    this.message,
  });

  /// The main button (usually a FilledButton). Expands to fill the row.
  final Widget action;

  /// Optional content on the left (amount summary or a secondary button).
  final Widget? leading;

  /// Optional short text above the row (e.g. "Accept the agreement to
  /// submit."). Shown in the secondary text color.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: SizedBox(height: 48, child: action)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
