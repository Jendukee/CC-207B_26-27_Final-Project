// The heart that saves an item to Favorites (customer redesign 2, Phase 1).
// Used on every item card (top-right of the photo), in the Item details
// header and on the Favorites screen.
//
// * A white circle behind the heart keeps it visible on any photo and on
//   the maroon header. Outline heart = not saved; filled maroon = saved.
// * 48 x 48 px tap target; tooltip and screen-reader label "Add to
//   favorites" / "Remove from favorites" (H4, accessibility).
// * It is its own button, so tapping it never opens the item.
// * Signed in: the heart changes at once (optimistic, H1), with a snackbar
//   "Saved to favorites" + Undo, or "Removed from favorites" (Undo too when
//   [undoOnRemove], e.g. on the Favorites screen) (H3). If saving fails,
//   the heart goes back and an error is shown (H9).
// * Guest: sent to Login ("Sign in to save favorites") and the item is
//   saved after signing in (see favorite_links.dart). Back from Login
//   saves nothing (H3).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/features/catalog/models/favorite_links.dart';
import 'package:orange150_rental/features/catalog/services/favorites_controller.dart';

/// The heart button for [itemId].
class FavoriteButton extends StatelessWidget {
  /// Creates the heart. [controller] defaults to the app's.
  const FavoriteButton({
    super.key,
    required this.itemId,
    this.itemName,
    this.undoOnRemove = false,
    this.controller,
  });

  /// The item saved or removed.
  final String itemId;

  /// Item name, added to the screen-reader label when given.
  final String? itemName;

  /// Offer Undo after removing too (the Favorites screen).
  final bool undoOnRemove;

  /// For tests; null uses [FavoritesController.instance].
  final FavoritesController? controller;

  FavoritesController get _controller =>
      controller ?? FavoritesController.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final saved = _controller.isFavorite(itemId);
        final label = saved ? 'Remove from favorites' : 'Add to favorites';
        void onTap() => toggleFavorite(
          context,
          itemId,
          controller: _controller,
          undoOnRemove: undoOnRemove,
        );
        // One screen-reader node: "Add to favorites, <item>", a toggle
        // button (the tooltip text would otherwise be read twice).
        return Semantics(
          button: true,
          toggled: saved,
          label: itemName == null ? label : '$label, $itemName',
          onTap: onTap,
          excludeSemantics: true,
          child: IconButton(
            tooltip: label,
            onPressed: onTap,
            // The IconButton gives the 48 px target; the circle is smaller.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
              ),
              child: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: saved ? AppColors.maroon : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Saves or removes [itemId] with feedback (see the file header). Guests
/// are sent to Login instead.
Future<void> toggleFavorite(
  BuildContext context,
  String itemId, {
  FavoritesController? controller,
  bool undoOnRemove = false,
}) async {
  final favorites = controller ?? FavoritesController.instance;

  // Guests: Login, then back here with the item saved (favorite_links).
  // push, so Back from Login returns here without saving (H3).
  if (!favorites.isSignedIn) {
    final here = GoRouterState.of(context).uri;
    context.push(FavoriteLinks.loginFor(here, itemId));
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final saving = !favorites.isFavorite(itemId);
  final future = favorites.setFavorite(itemId, saving); // heart flips now

  // Feedback right away (optimistic), with Undo (H1, H3).
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        // Flutter keeps a snackbar with an action on screen until it is
        // tapped. persist: false makes it close after [duration] anyway.
        persist: false,
        content: Text(saving ? 'Saved to favorites' : 'Removed from favorites'),
        action: saving || undoOnRemove
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () =>
                    favorites.setFavorite(itemId, !saving).catchError((_) {}),
              )
            : null,
      ),
    );

  try {
    await future;
  } catch (error) {
    // The controller already put the heart back; say why (H9).
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: saving
                  ? 'Could not save to favorites. Please try again.'
                  : 'Could not remove from favorites. Please try again.',
            ),
          ),
        ),
      );
  }
}
