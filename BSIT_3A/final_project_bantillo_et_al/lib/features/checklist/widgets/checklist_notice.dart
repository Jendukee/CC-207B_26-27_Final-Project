// Colored notice box used on the checklist screens: the balance-due
// banner (with a "Record payment" button) and the save error (with a
// "Retry" button). The text always carries the meaning, not color alone.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

/// A tinted box with an icon, a message and an optional button.
class ChecklistNotice extends StatelessWidget {
  /// Creates the notice.
  const ChecklistNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  /// Leading icon.
  final IconData icon;

  /// Border, icon and tint color.
  final Color color;

  /// What happened / what to do.
  final String message;

  /// Optional button text, e.g. "Record payment".
  final String? actionLabel;

  /// Optional button icon.
  final IconData? actionIcon;

  /// Called when the button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.arrow_forward),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
