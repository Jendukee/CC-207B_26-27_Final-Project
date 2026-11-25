// A row of choices in one white rounded box (calendar filter design):
//
//   ┌──────────────────────┐   ┌───────────────────────────┐
//   │ [Month]   Week       │   │ [All]  Gowns  Suits  ...  │
//   └──────────────────────┘   └───────────────────────────┘
//      filled style               tint style
//
// * filled: the chosen option is solid maroon with white text (the view
//   switch, Month / Week).
// * tint: the chosen option is light pink with maroon text (the category
//   filter).
// * Other options: grey text on white. Each option is 44 px tall inside
//   the 4 px frame (48 px total target) and is announced as a selected /
//   unselected button, so the choice is never shown by color alone (H6).
//
// Display only: the screen passes the options, the current value and what
// a tap does.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// How the chosen option is drawn.
enum SegmentStyle {
  /// Solid maroon, white text.
  filled,

  /// Light pink, maroon text.
  tint,
}

/// One white box of choices.
class CalendarSegmentGroup<T> extends StatelessWidget {
  /// Creates the group.
  const CalendarSegmentGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.style = SegmentStyle.filled,
  });

  /// The choices: value and label, in order.
  final List<(T, String)> options;

  /// The current value.
  final T selected;

  /// Called with the tapped value.
  final ValueChanged<T> onSelected;

  /// How the chosen option looks.
  final SegmentStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineSoft, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            _option(value, label, value == selected),
        ],
      ),
    );
  }

  Widget _option(T value, String label, bool isSelected) {
    final (Color background, Color text) = !isSelected
        ? (Colors.transparent, AppColors.textMuted)
        : style == SegmentStyle.filled
        ? (AppColors.maroon, Colors.white)
        : (AppColors.tintPink, AppColors.maroon);
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
