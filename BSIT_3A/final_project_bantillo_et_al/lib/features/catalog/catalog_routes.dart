// Routes owned by the catalog feature (Browse tab of the customer shell).
// Combined into the customer StatefulShellRoute by core/router/app_router.dart.
//
// Customer redesign 2 (Phase 1):
//   * /browse/favorites: the Favorites screen.
//   * A redirect on /browse (it also runs for every page under it) saves
//     the item a guest hearted before signing in (?fav=<itemId>, see
//     models/favorite_links.dart), then removes ?fav from the address and
//     confirms with "Saved to favorites" (H1).
//
// OWNER: Member 1.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/widgets/app_messenger.dart';
import 'package:orange150_rental/features/catalog/models/favorite_links.dart';
import 'package:orange150_rental/features/catalog/screens/browse_screen.dart';
import 'package:orange150_rental/features/catalog/screens/favorites_screen.dart';
import 'package:orange150_rental/features/catalog/screens/item_details_screen.dart';
import 'package:orange150_rental/features/catalog/services/favorites_controller.dart';

/// Saves a favorite that was waiting for sign-in, with a snackbar.
void _savePending(String itemId) {
  FavoritesController.instance
      .setFavorite(itemId, true)
      .then(
        (_) => AppMessenger.show('Saved to favorites'),
        onError: (Object error) => AppMessenger.show(
          friendlyErrorMessage(
            error,
            fallback: 'Could not save to favorites. Please try again.',
          ),
        ),
      );
}

/// Browse (/browse), Item Details (/browse/item/:itemId) and Favorites
/// (/browse/favorites). Open to guests (Favorites asks them to sign in).
final List<RouteBase> catalogRoutes = [
  GoRoute(
    path: RoutePaths.browse,
    name: RouteNames.browse,
    redirect: (context, state) => FavoriteLinks.pendingRedirect(
      state.uri,
      signedIn: FavoritesController.instance.isSignedIn,
      save: _savePending,
    ),
    builder: (context, state) => const BrowseScreen(),
    routes: [
      GoRoute(
        path: RoutePaths.itemDetails,
        name: RouteNames.itemDetails,
        builder: (context, state) =>
            ItemDetailsScreen(itemId: state.pathParameters['itemId']!),
      ),
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  ),
];
