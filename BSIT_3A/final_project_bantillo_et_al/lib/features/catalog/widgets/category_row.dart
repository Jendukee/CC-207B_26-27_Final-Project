// Horizontal row of category shortcuts with icons (customer redesign,
// Phase 1): Gowns, Long Gowns, Suits, Bearer, Kids, Adult. Tapping one
// switches that filter on (or off again). Selected categories get a maroon
// ring and bold label, so selection is not shown by color alone.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';

/// The category shortcuts.
class CategoryRow extends StatelessWidget {
  /// Creates the row for the current [filter].
  const CategoryRow({super.key, required this.filter, required this.onTap});

  /// Current filter (decides which categories look selected).
  final ItemFilter filter;

  /// Called with the tapped category.
  final ValueChanged<BrowseCategory> onTap;

  static const Map<BrowseCategory, IconData> _icons = {
    BrowseCategory.gowns: Icons.checkroom,
    BrowseCategory.longGowns: Icons.woman,
    BrowseCategory.suits: Icons.man,
    BrowseCategory.bearer: Icons.child_care,
    BrowseCategory.kids: Icons.child_friendly,
    BrowseCategory.adult: Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final category in BrowseCategory.values)
            _CategoryButton(
              label: category.label,
              icon: _icons[category]!,
              selected: category.isSelectedIn(filter),
              onTap: () => onTap(category),
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label category${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldTint,
                  border: Border.all(
                    color: selected ? AppColors.maroon : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: AppColors.maroon),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
