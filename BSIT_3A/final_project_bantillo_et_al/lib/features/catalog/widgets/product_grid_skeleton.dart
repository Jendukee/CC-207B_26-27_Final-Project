// Product grid layout shared by the real grid and its skeleton, plus the
// skeleton itself (grey cards shown while Browse loads, so the page does
// not jump when the items arrive).
//
// Grid (Figma design): 2 columns on phones, 3 from 700 px, 4 from 1000 px,
// 12 px between columns and 16 px between rows. Each cell is tall enough
// for a photo with the design's 0.71 shape plus the text below it.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/skeleton_box.dart';

/// Height reserved under the photo for name, type/size, price and
/// "View details" (a little extra so larger text settings still fit).
const double productCardTextHeight = 150;

/// Width / height of the photo in the design.
const double productPhotoAspect = 0.71;

/// Columns for a grid [width] wide (design breakpoints).
int productGridColumns(double width) => width >= 1000
    ? 4
    : width >= 700
    ? 3
    : 2;

/// The grid layout for a grid [width] wide (without its side padding).
SliverGridDelegate productGridDelegate(double width) {
  const spacing = 12.0;
  final columns = productGridColumns(width);
  final cardWidth = (width - spacing * (columns - 1)) / columns;
  final cardHeight = cardWidth / productPhotoAspect + productCardTextHeight;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: 16,
    childAspectRatio: cardWidth / cardHeight,
  );
}

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
        Expanded(child: SkeletonBox(radius: 12)),
        SizedBox(height: 10),
        SkeletonBox(height: 14),
        SizedBox(height: 6),
        SkeletonBox(height: 12, width: 80),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: 90),
        SizedBox(height: 10),
        SkeletonBox(height: 12, width: 70),
        SizedBox(height: 12),
      ],
    );
    // SliverLayoutBuilder gives the grid width to size the cells.
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        gridDelegate: productGridDelegate(constraints.crossAxisExtent),
        itemCount: count,
        // The first card carries the one "Loading items" label for screen
        // readers (the grey blocks themselves are hidden from them).
        itemBuilder: (context, index) => index == 0
            ? Semantics(label: 'Loading items', liveRegion: true, child: card)
            : card,
      ),
    );
  }
}
