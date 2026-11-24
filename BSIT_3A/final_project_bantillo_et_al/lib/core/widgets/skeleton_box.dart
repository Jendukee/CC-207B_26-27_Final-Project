// Grey placeholder blocks shown while content loads ("skeleton" loading),
// so the page keeps its shape instead of showing a spinner (heuristic H1).
// The blocks gently pulse. Screen readers hear one "Loading" label.
//
// Example (a product card skeleton):
//   Column(children: [
//     SkeletonBox(aspectRatio: 1),       // photo
//     SizedBox(height: 8),
//     SkeletonBox(height: 14, width: 120) // name
//   ])
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// One pulsing grey block.
class SkeletonBox extends StatefulWidget {
  /// Creates a block with a fixed [height] (and optional [width]), or a
  /// block with an [aspectRatio] that fills the available width.
  const SkeletonBox({
    super.key,
    this.height,
    this.width,
    this.aspectRatio,
    this.radius = 8,
  });

  /// Fixed height in pixels.
  final double? height;

  /// Fixed width; null fills the available width.
  final double? width;

  /// Width / height ratio (e.g. 1 for a square photo).
  final double? aspectRatio;

  /// Corner radius.
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  // Fades between two greys and back, forever, while on screen.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
    final sized = widget.aspectRatio == null
        ? box
        : AspectRatio(aspectRatio: widget.aspectRatio!, child: box);
    return ExcludeSemantics(child: sized);
  }
}
