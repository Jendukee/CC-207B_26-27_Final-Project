// Skeleton version of the product grid, shown while Browse loads (customer
// redesign, Phase 1). It has the same shape as real ProductCards, so the
// page does not jump when the items arrive.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/skeleton_box.dart';

/// A sliver grid of placeholder product cards.
class ProductGridSkeleton extends StatelessWidget {
  /// Creates the skeleton grid with [count] cards.
  const ProductGridSkeleton({super.key, this.count = 6});

  /// How many placeholder cards to show.
  final int count;

  @override
  Widget build(BuildContext context) {
    const card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SkeletonBox(radius: 10)),
        SizedBox(height: 8),
        SkeletonBox(height: 14),
        SizedBox(height: 6),
        SkeletonBox(height: 14, width: 90),
        SizedBox(height: 6),
        SkeletonBox(height: 12, width: 60),
      ],
    );
    return SliverGrid.builder(
      gridDelegate: productGridDelegate,
      itemCount: count,
      // The first card carries the one "Loading items" label for screen
      // readers (the grey blocks themselves are hidden from them).
      itemBuilder: (context, index) => index == 0
          ? Semantics(label: 'Loading items', liveRegion: true, child: card)
          : card,
    );
  }
}

/// Grid layout shared by the real grid and the skeleton: 2 columns on
/// phones (cards about 180 px wide), more on tablets and the web.
const SliverGridDelegate productGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      // Photo + up to ~200 px of text below it (2-line name, price, size,
      // tag). On a 360 px phone a card is ~168 x 365 px, so the photo is
      // about square. The card's photo shrinks if the text needs more.
      childAspectRatio: 0.46,
    );
