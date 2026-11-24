// Text category tabs under the Browse search bar: All, Gowns, Long Gowns,
// Suits, Bearer, Kids, Adult. The selected tab is dark with a short
// underline (selection is shown by weight and the line, not color alone).
//
// Logic (unchanged from the customer redesign, Phase 1):
//   * a category tab switches its filter on, or off again when tapped twice
//   * type and age categories combine (e.g. Suits + Kids)
//   * "All" clears both the type and the age-group filter
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';

/// The category tabs.
class CategoryRow extends StatelessWidget {
  /// Creates the tabs for the current [filter].
  const CategoryRow({
    super.key,
    required this.filter,
    required this.onTap,
    required this.onAll,
    this.trailing,
  });

  /// A button pinned at the right end, e.g. the Favorites heart.
  final Widget? trailing;

  /// Current filter (decides which tabs look selected).
  final ItemFilter filter;

  /// Called with the tapped category.
  final ValueChanged<BrowseCategory> onTap;

  /// Called when "All" is tapped.
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final noCategory = filter.type == null && filter.ageGroup == null;
    final tabs = ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _CategoryTab(label: 'All', selected: noCategory, onTap: onAll),
        for (final category in BrowseCategory.values)
          _CategoryTab(
            label: category.label,
            selected: category.isSelectedIn(filter),
            onTap: () => onTap(category),
          ),
      ],
    );
    return SizedBox(
      height: 48,
      // Customer redesign 2: [trailing] (the Favorites heart) is pinned to
      // the right, OUTSIDE the scrolling list, so it never scrolls away
      // (H6 recognition, H7 efficiency).
      child: trailing == null
          ? tabs
          : Row(
              children: [
                Expanded(child: tabs),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailing,
                ),
              ],
            ),
    );
  }
}

/// One text tab with an underline when selected. The tap area is at
/// least 48 px tall.
class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    // textSecondary instead of light grey: passes WCAG AA.
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 20 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
