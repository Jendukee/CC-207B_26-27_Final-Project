// Checkbox list of every garment and inclusion, grouped by item.
// Display only: the screen owns which boxes are ticked.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/features/checklist/models/checklist_rules.dart';

/// Grouped checkboxes for the checklist.
class InclusionChecklist extends StatelessWidget {
  /// Creates the list.
  const InclusionChecklist({
    super.key,
    required this.lines,
    required this.ticked,
    required this.onChanged,
    this.enabled = true,
    this.uncheckedHint,
  });

  /// All checkboxes, in order.
  final List<InclusionLine> lines;

  /// Keys of the ticked lines.
  final Set<String> ticked;

  /// Called with a line key and its new value.
  final void Function(String key, bool value) onChanged;

  /// False while saving.
  final bool enabled;

  /// Shown under unticked lines, e.g. "Missing" on returns.
  final String? uncheckedHint;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Text('This booking has no items.');
    }
    final theme = Theme.of(context);
    final children = <Widget>[];
    String? currentItem;

    for (final line in lines) {
      // A heading each time a new item starts.
      if (line.itemName != currentItem) {
        currentItem = line.itemName;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(line.itemName, style: theme.textTheme.titleSmall),
          ),
        );
      }
      final isTicked = ticked.contains(line.key);
      children.add(
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: isTicked,
          title: Text(line.label),
          subtitle: !isTicked && uncheckedHint != null
              ? Text(uncheckedHint!)
              : null,
          onChanged: enabled
              ? (value) => onChanged(line.key, value ?? false)
              : null,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
