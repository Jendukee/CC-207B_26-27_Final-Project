// The "Favorites" heart pinned at the right end of the Browse category row
// (customer redesign 2, Phase 1). It opens the Favorites screen, and a gold
// badge shows how many items are saved (H1 visibility of system status,
// H6 recognition rather than recall, H7 efficiency).
//
// 48 x 48 px; tooltip and screen-reader label "Favorites" (with the count).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/catalog/services/favorites_controller.dart';

/// Heart button that opens Favorites.
class FavoritesShortcut extends StatelessWidget {
  /// Creates the button. [controller] defaults to the app's.
  const FavoritesShortcut({super.key, this.controller});

  /// For tests; null uses [FavoritesController.instance].
  final FavoritesController? controller;

  @override
  Widget build(BuildContext context) {
    final favorites = controller ?? FavoritesController.instance;
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        final count = favorites.count;
        return Semantics(
          button: true,
          label: count == 0 ? 'Favorites' : 'Favorites, $count saved',
          excludeSemantics: true,
          onTap: () => context.push(RoutePaths.favoritesFull),
          child: IconButton(
            tooltip: 'Favorites',
            onPressed: () => context.push(RoutePaths.favoritesFull),
            icon: Badge(
              isLabelVisible: count > 0,
              // Gold fill with near-black text: gold is never text on white.
              backgroundColor: AppColors.gold,
              textColor: AppColors.textPrimary,
              label: Text(count > 99 ? '99+' : '$count'),
              child: const Icon(Icons.favorite_border, color: AppColors.maroon),
            ),
          ),
        );
      },
    );
  }
}
