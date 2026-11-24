// One item in the staff Inventory grid (shop-side redesign, Phase 2), laid
// out like the customer Browse card so staff see items the way customers
// do (H4): a tall photo with the condition chip in its corner, the name
// (2 lines max), "Type · Age group · Size", the price in maroon and "Edit".
// The whole card is one 48 px+ tap target that opens the item form.
//
// Also here: the grid layout (2 columns on phones, 3 from 700 px, 4 from
// 1000 px, the same breakpoints as Browse) and its skeleton. Copied from
// the catalog layout on purpose: features never import each other.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/skeleton_box.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Height under the photo for the name, details, price and "Edit".
const double inventoryCardTextHeight = 140;

/// Width / height of the photo (same shape as Browse).
const double inventoryPhotoAspect = 0.71;

/// The grid layout for a grid [width] wide (without side padding).
SliverGridDelegate inventoryGridDelegate(double width) {
  const spacing = 12.0;
  final columns = width >= 1000
      ? 4
      : width >= 700
      ? 3
      : 2;
  final cardWidth = (width - spacing * (columns - 1)) / columns;
  final cardHeight = cardWidth / inventoryPhotoAspect + inventoryCardTextHeight;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: 12,
    childAspectRatio: cardWidth / cardHeight,
  );
}

/// Condition chip colors, dark enough for white text (UI audit #19).
Color inventoryConditionColor(ItemCondition condition) => switch (condition) {
  ItemCondition.available => AppColors.success,
  ItemCondition.cleaningRepair => AppColors.warningOrange,
  ItemCondition.retired => AppColors.neutralGrey,
};

/// A grid card for one inventory item.
class InventoryItemCard extends StatelessWidget {
  /// Creates the card.
  const InventoryItemCard({super.key, required this.item, required this.onTap});

  /// The item.
  final Item item;

  /// Opens the item form (edit).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = item.size.isEmpty ? 'No size' : item.size;
    return Semantics(
      button: true,
      label:
          '${item.name}, ${item.type.label}, ${item.ageGroup.label}, size '
          '$size, ${Formatters.peso(item.price)}, ${item.condition.label}. '
          'Edit item.',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo with the condition chip (text + color, never color
              // alone).
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.photoUrls.isNotEmpty)
                      Image.network(
                        item.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(theme),
                      )
                    else
                      _placeholder(theme),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: StatusChip(
                          label: item.condition.label,
                          color: inventoryConditionColor(item.condition),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.type.label} · ${item.ageGroup.label} · $size',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.peso(item.price),
                      style: const TextStyle(
                        color: AppColors.maroon,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.checkroom,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Grey placeholder cards in the same grid while the inventory loads.
class InventoryGridSkeleton extends StatelessWidget {
  /// Creates [count] placeholder cards.
  const InventoryGridSkeleton({super.key, this.count = 6});

  /// How many cards.
  final int count;

  @override
  Widget build(BuildContext context) {
    const card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SkeletonBox(radius: 12)),
        SizedBox(height: 10),
        SkeletonBox(height: 14),
        SizedBox(height: 6),
        SkeletonBox(height: 12, width: 90),
        SizedBox(height: 8),
        SkeletonBox(height: 14, width: 70),
        SizedBox(height: 24),
      ],
    );
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        gridDelegate: inventoryGridDelegate(constraints.crossAxisExtent),
        itemCount: count,
        itemBuilder: (context, index) => index == 0
            ? Semantics(
                label: 'Loading inventory',
                liveRegion: true,
                child: card,
              )
            : card,
      ),
    );
  }
}
