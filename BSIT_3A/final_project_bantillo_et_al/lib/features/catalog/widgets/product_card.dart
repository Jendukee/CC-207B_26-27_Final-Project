// One product in the Browse grid, like a shopping app listing (customer
// redesign, Phase 1): square photo, name (2 lines max), price in maroon
// bold, an optional availability tag and the size. The whole card is one
// tap target that opens Item details.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// A grid card for one item.
class ProductCard extends StatelessWidget {
  /// Creates the card.
  const ProductCard({
    super.key,
    required this.item,
    required this.onTap,
    this.tag,
  });

  /// The item shown.
  final Item item;

  /// Opens the item details.
  final VoidCallback onTap;

  /// Optional "Available on your date" / "Few dates left" tag.
  final AvailabilityTag? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo: takes the space the text below does not need, so the
            // card never overflows, even with large text settings. The
            // grid cell is sized so it is about square on phones.
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: item.photoUrls.isEmpty
                    ? _placeholder(theme)
                    : Image.network(
                        item.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(theme),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.peso(item.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.maroon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Size ${item.size}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (tag != null) ...[
                    const SizedBox(height: 6),
                    _TagChip(tag: tag!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.checkroom, size: 48)),
  );
}

/// Small outlined tag. "Few dates left" is urgent, so it uses deep red;
/// "Available on your date" uses the success green. Both have text.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final AvailabilityTag tag;

  @override
  Widget build(BuildContext context) {
    final color = tag == AvailabilityTag.fewDatesLeft
        ? AppColors.deepRed
        : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
