// The app's header on every customer and staff screen (customer redesign 2,
// Phase 1): the Orange 150 mark, then the screen title.
//
//   [<-]  [mark]  Title                     [actions]
//
// * The mark is the SAME logo the Splash screen shows (the gold
//   Icons.checkroom mark on maroon). It is an icon glyph, not a bitmap, so it
//   stays sharp at any size and keeps its shape. No new image was added.
// * Gold on the maroon header is about 5:1 (non-text contrast needs 3:1),
//   so it needs no white badge.
// * The mark is NOT a button: tapping it does nothing, so nobody leaves a
//   half-filled form by accident (H3, H5).
// * The back arrow (automatic, or [leading]) comes first, then the mark and
//   the title. Actions and every other AppBar option pass straight through.
//
// Heuristics: H4 consistency and standards (one header everywhere),
// H8 aesthetic and minimalist design (small mark, short title).
//
// Staff dashboard design: optional [toolbarHeight], [backgroundColor] and
// [titleTextStyle] let the Dashboard use its taller dark maroon header on
// wide screens. Left out, the header looks exactly as before.
//
// [showLogo] false hides the mark (the staff screens: the Orange 150 logo
// is already in the staff sidebar). Default true, so nothing else changes.
//
// [titleSpacing] moves the title left / right (the gap before it). Left
// out, Flutter's default 16 px is used, as before.
//
// Example:
//   appBar: const BrandAppBar(title: 'My Bookings'),
//   appBar: BrandAppBar(title: 'Item details', actions: [heart]),
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// The mark on a small maroon rounded badge, exactly as on the Splash
/// screen, for WHITE surfaces such as the staff NavigationRail (Phase 2):
/// gold straight on white would be too faint (below 3:1), gold on maroon
/// is about 5:1. Not a button.
class BrandBadge extends StatelessWidget {
  /// Creates the badge, [size] px square.
  const BrandBadge({super.key, this.size = 44});

  /// Width and height of the badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: BrandLogo(size: size * 0.64),
    );
  }
}

/// The Orange 150 mark (the Splash screen logo), about [size] px tall.
class BrandLogo extends StatelessWidget {
  /// Creates the mark.
  const BrandLogo({super.key, this.size = 32});

  /// Height of the mark in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    // semanticLabel: screen readers say "Orange 150" once, before the
    // title. Not wrapped in a button: it has no tap action.
    return Icon(
      Icons.checkroom,
      size: size,
      color: AppColors.gold,
      semanticLabel: 'Orange 150',
    );
  }
}

/// An [AppBar] with the Orange 150 mark before the title.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the header. Give [title] (text) or [titleWidget].
  const BrandAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.toolbarHeight,
    this.backgroundColor,
    this.titleTextStyle,
    this.showLogo = true,
    this.titleSpacing,
  }) : assert(title != null || titleWidget != null);

  /// Space before the title (after the back arrow, or from the left edge
  /// when there is none), as in [AppBar.titleSpacing]. Null = Flutter's
  /// default (16), so screens that leave it out look exactly as before.
  final double? titleSpacing;

  /// False hides the Orange 150 mark before the title.
  final bool showLogo;

  /// Header height; null = the standard [kToolbarHeight].
  final double? toolbarHeight;

  /// Header color; null = the theme's maroon.
  final Color? backgroundColor;

  /// Title style; null = the theme's.
  final TextStyle? titleTextStyle;

  /// Screen title, e.g. "My Bookings".
  final String? title;

  /// A custom title (e.g. title + reference number); used instead of
  /// [title].
  final Widget? titleWidget;

  /// Buttons on the right, as in [AppBar.actions].
  final List<Widget>? actions;

  /// A custom back / close button, as in [AppBar.leading].
  final Widget? leading;

  /// Shows the back arrow automatically when the screen can go back.
  final bool automaticallyImplyLeading;

  /// Optional tab bar or progress bar under the header.
  final PreferredSizeWidget? bottom;

  /// Passed to [AppBar.elevation].
  final double? elevation;

  /// Passed to [AppBar.scrolledUnderElevation].
  final double? scrolledUnderElevation;

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: backgroundColor,
      titleTextStyle: titleTextStyle,
      titleSpacing: titleSpacing,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      title: Row(
        children: [
          if (showLogo) ...[const BrandLogo(), const SizedBox(width: 10)],
          // Flexible + ellipsis: a long title never pushes the actions off.
          Flexible(
            child:
                titleWidget ??
                Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
