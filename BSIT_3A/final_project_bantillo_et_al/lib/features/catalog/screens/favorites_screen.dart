// Favorites (/browse/favorites, customer redesign 2, Phase 1): the gowns and
// suits the customer saved with the heart.
//
// * The same 2-column grid and item cards as Browse, hearts filled.
// * Removing a heart removes the card at once, with Undo in the snackbar
//   (Undo brings the card back) (H1, H3).
// * Skeleton cards while loading, ErrorView with Retry, and an empty state
//   with a "Browse items" button (H9, H10).
// * Guests see a sign-in prompt (they have no saved items yet).
// * Retired items are left out by FavoritesService.
//
// Opened from the heart at the end of the Browse category row and from the
// Profile Me page (by path only).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/sign_in_prompt.dart';
import 'package:orange150_rental/features/catalog/services/favorites_controller.dart';
import 'package:orange150_rental/features/catalog/widgets/product_card.dart';
import 'package:orange150_rental/features/catalog/widgets/product_grid_skeleton.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// The customer's saved items.
class FavoritesScreen extends StatefulWidget {
  /// Creates the screen. [controller] defaults to the app's.
  const FavoritesScreen({super.key, this.controller});

  /// For tests; null uses [FavoritesController.instance].
  final FavoritesController? controller;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesController _favorites =
      widget.controller ?? FavoritesController.instance;

  /// The saved items; started on first build while signed in.
  Future<List<Item>>? _future;

  /// Retry and pull to refresh.
  Future<void> _reload() async {
    setState(() => _future = _favorites.api.myFavoriteItems());
    try {
      await _future;
    } catch (_) {
      // ErrorView shows it.
    }
  }

  void _openItem(Item item) => context.pushNamed(
    RouteNames.itemDetails,
    pathParameters: {'itemId': item.id},
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const BrandAppBar(title: 'Favorites'),
      // Rebuilds on sign in / out (the controller follows the session), so
      // a guest who signs in from here sees their list without reopening.
      body: ListenableBuilder(
        listenable: _favorites,
        builder: (context, _) {
          if (!_favorites.isSignedIn) {
            _future = null;
            return const SignInPrompt(
              message: 'Sign in to see the gowns and suits you saved.',
              from: RoutePaths.favoritesFull,
            );
          }
          _future ??= _favorites.api.myFavoriteItems();
          return RefreshIndicator(onRefresh: _reload, child: _body());
        },
      ),
    );
  }

  Widget _body() {
    return FutureBuilder<List<Item>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: ProductGridSkeleton(count: 4),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return _fill(
            ErrorView(
              message: friendlyErrorMessage(
                snapshot.error!,
                fallback: 'Unable to load your favorites. Please try again.',
              ),
              onRetry: _reload,
            ),
          );
        }
        // Rebuilds when a heart changes: a removed item disappears, and
        // comes back on Undo (it is still in the loaded list).
        return ListenableBuilder(
          listenable: _favorites,
          builder: (context, _) {
            final items = [
              for (final item in snapshot.requireData)
                if (_favorites.isFavorite(item.id)) item,
            ];
            if (items.isEmpty) {
              return _fill(
                EmptyView(
                  icon: Icons.favorite_border,
                  message:
                      'No favorites yet. Tap the heart on any gown or suit '
                      'to save it here.',
                  actionLabel: 'Browse items',
                  onAction: () => context.go(RoutePaths.browse),
                ),
              );
            }
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) => SliverGrid.builder(
                      gridDelegate: productGridDelegate(
                        constraints.crossAxisExtent,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => ProductCard(
                        key: ValueKey(items[index].id),
                        item: items[index],
                        onTap: () => _openItem(items[index]),
                        undoOnRemove: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// A full-height, still scrollable page (so pull to refresh works).
  Widget _fill(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
}
