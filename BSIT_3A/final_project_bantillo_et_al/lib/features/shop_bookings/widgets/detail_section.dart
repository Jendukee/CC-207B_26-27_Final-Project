// Small layout helpers for the booking details screen: a titled card
// section, a label/value row and a colored notice box.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

/// A card with a title and some content, used for each details section.
class DetailSection extends StatelessWidget {
  /// Creates a section titled [title].
  const DetailSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  /// Section heading, e.g. "Customer".
  final String title;

  /// Optional icon before the heading.
  final IconData? icon;

  /// Section content.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// "Label ........ value" on one line.
class DetailRow extends StatelessWidget {
  /// Creates a row. [emphasize] makes the value bold.
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  /// Left text.
  final String label;

  /// Right text.
  final String value;

  /// Bold value (used for the balance).
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasize
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A colored box with an icon and text. The text always carries the
/// meaning, so it does not rely on color alone.
class NoticeBox extends StatelessWidget {
  /// Creates a notice.
  const NoticeBox({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  /// Leading icon.
  final IconData icon;

  /// Border, icon and tint color.
  final Color color;

  /// The message.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
