// One product in the Browse grid (Figma design): a tall photo with an
// availability badge in the top-left corner, then the name (2 lines max),
// "Type · Size", the price in maroon with "/ rental", and "View details".
// The whole card is one tap target that opens Item details.
//
// Badge text comes from the availability logic (catalog_rules.dart):
//   "FEW DATES LEFT" (deep red), "AVAILABLE ON YOUR DATE" (green), or
//   "AVAILABLE" when there is no special tag (Browse only lists rentable
//   items).
//
// Layout safety: the photo takes the height the text does not need, so the
// card never overflows; the grid cell is sized so the photo keeps the
// design's 0.71 shape (see productGridDelegate).
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
    return Semantics(
      button: true,
      label:
          '${item.name}, ${item.type.label}, size ${item.size}, '
          '${Formatters.peso(item.price)} per rental. View details.',
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
              // Photo with the availability badge.
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
                    // left + right limit the badge to the card width, so
                    // a long label wraps instead of being cut off.
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _Badge(tag: tag),
                      ),
                    ),
                  ],
                ),
              ),

              // Details.
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
                      '${item.type.label} · ${item.size}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            Formatters.peso(item.price),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.maroon,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ rental',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'View details',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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
        Icons.image_outlined,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// White badge on the photo. The urgent "Few dates left" uses deep red
/// text; the others near-black / green. All pass WCAG AA on white.
class _Badge extends StatelessWidget {
  const _Badge({this.tag});

  final AvailabilityTag? tag;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (tag) {
      AvailabilityTag.fewDatesLeft => ('FEW DATES LEFT', AppColors.deepRed),
      AvailabilityTag.availableOnYourDate => (
        'AVAILABLE ON YOUR DATE',
        AppColors.success,
      ),
      null => ('AVAILABLE', AppColors.textPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        maxLines: 2,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
