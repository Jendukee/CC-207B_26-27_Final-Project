// Full-width, swipeable photo carousel for Item details (customer
// redesign, Phase 1), with a dot page indicator and a "2 / 4" counter.
// Square photos, like a product page. Items without photos show an icon.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Swipeable item photos.
class PhotoCarousel extends StatefulWidget {
  /// Creates the carousel for [urls].
  const PhotoCarousel({super.key, required this.urls, required this.label});

  /// Public photo URLs (item-photos bucket).
  final List<String> urls;

  /// Item name, read by screen readers ("Photo 1 of 3 of ...").
  final String label;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.urls.length;

    Widget placeholder() => ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.checkroom, size: 72)),
    );

    if (count == 0) return AspectRatio(aspectRatio: 1, child: placeholder());

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: count,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Semantics(
              image: true,
              label: 'Photo ${index + 1} of $count of ${widget.label}',
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder(),
              ),
            ),
          ),
          if (count > 1) ...[
            // "2 / 4" counter (dark pill, white text: readable on any photo).
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_page + 1} / $count',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Dots.
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.maroon : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.maroon),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
