// Grey placeholder cards shown while a list of bookings loads (shop-side
// redesign, Phase 2), in the same shape as the real cards (photo square,
// three text lines, a chip), so the page does not jump when data arrives.
// Used by the staff bookings list, the dashboard lists and the calendar
// day list; the customer side uses the product grid skeleton.
//
// H1 visibility of system status (something is loading, and what shape),
// H4 consistency with the customer skeletons.
//
// Example:
//   const ListSkeleton(count: 4)
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/skeleton_box.dart';

/// [count] placeholder booking cards in a column.
class ListSkeleton extends StatelessWidget {
  /// Creates the skeleton.
  const ListSkeleton({
    super.key,
    this.count = 4,
    this.showPhoto = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  /// How many cards.
  final int count;

  /// Shows the photo square on the left.
  final bool showPhoto;

  /// Space around the cards.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One label for screen readers; the grey blocks are hidden from them.
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              for (var i = 0; i < count; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showPhoto) ...[
                          const SkeletonBox(height: 64, width: 64),
                          const SizedBox(width: 12),
                        ],
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 14, width: 120),
                              SizedBox(height: 8),
                              SkeletonBox(height: 12),
                              SizedBox(height: 8),
                              SkeletonBox(height: 12, width: 160),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SkeletonBox(height: 24, width: 64, radius: 12),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
