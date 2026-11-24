// A white content section with a title, used like the blocks of a product
// or order page (customer redesign, Phase 1). Customer and staff screens
// both use it, so the two sides look the same: same padding, corner radius
// and heading style.
//
// Put SectionCards on a light grey page background (Scaffold background
// colorScheme.surfaceContainerLow) to get the "white cards separated by
// grey gaps" look.
//
// Example:
//   SectionCard(
//     title: 'Rental schedule',
//     icon: Icons.event,
//     child: Column(children: [...]),
//   )
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// A titled white card.
class SectionCard extends StatelessWidget {
  /// Creates the card. [title] may be null for a card without heading.
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  /// Section heading, e.g. "Contact details".
  final String? title;

  /// Optional icon before the heading.
  final IconData? icon;

  /// Optional widget at the right of the heading (e.g. an Edit button).
  final Widget? trailing;

  /// The section content.
  final Widget child;

  /// Space inside the card.
  final EdgeInsetsGeometry padding;

  /// Space around the card (the grey gap).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title!, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
