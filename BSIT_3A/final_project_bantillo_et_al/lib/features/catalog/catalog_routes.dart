// Routes owned by the catalog feature (Browse tab of the customer shell).
// Combined into the customer StatefulShellRoute by core/router/app_router.dart.
//
// OWNER: Member 1.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/catalog/screens/browse_screen.dart';
import 'package:orange150_rental/features/catalog/screens/item_details_screen.dart';

/// Browse (/browse) and Item Details (/browse/item/:itemId). Open to guests.
final List<RouteBase> catalogRoutes = [
  GoRoute(
    path: RoutePaths.browse,
    name: RouteNames.browse,
    builder: (context, state) => const BrowseScreen(),
    routes: [
      GoRoute(
        path: RoutePaths.itemDetails,
        name: RouteNames.itemDetails,
        builder: (context, state) =>
            ItemDetailsScreen(itemId: state.pathParameters['itemId']!),
      ),
    ],
  ),
];
