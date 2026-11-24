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
// Customer redesign 2: with [onMessageTap] the message becomes a 48 px
// link with an arrow (e.g. the checkout scrolls to "Sign and submit"), so
// the reason also leads to the fix (H5, H7, H9).
//
// Shop-side redesign (Phase 2): [secondary] adds a row of outlined buttons
// above the main row (e.g. staff booking details: "Mark picked up" and a
// red "Cancel booking"), each sharing the width equally; the ONE filled
// button stays at the bottom (H4, H8).
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
    this.onMessageTap,
    this.secondary = const [],
  });

  /// Outlined buttons shown in a row above the main row.
  final List<Widget> secondary;

  /// Makes [message] tappable (e.g. scroll to the field that is missing).
  final VoidCallback? onMessageTap;

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
              if (message != null && onMessageTap == null) ...[
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Tappable reason: a 48 px text button with an arrow.
              if (message != null && onMessageTap != null) ...[
                TextButton.icon(
                  onPressed: onMessageTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(message!, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
              ],
              if (secondary.isNotEmpty) ...[
                Row(
                  children: [
                    for (var i = 0; i < secondary.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(height: 48, child: secondary[i]),
                      ),
                    ],
                  ],
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
