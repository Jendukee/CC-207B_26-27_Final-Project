// Routes owned by the inventory feature (Inventory tab, staff shell).
// Combined into the staff StatefulShellRoute by core/router/app_router.dart.
// Staff/owner only (enforced by core/router/auth_guard.dart).
//
// OWNER: Member 1.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/inventory/screens/inventory_list_screen.dart';
import 'package:orange150_rental/features/inventory/screens/item_form_screen.dart';

/// /shop/inventory, /shop/inventory/new, /shop/inventory/:itemId/edit
final List<RouteBase> inventoryRoutes = [
  GoRoute(
    path: RoutePaths.inventory,
    name: RouteNames.inventory,
    builder: (context, state) => const InventoryListScreen(),
    routes: [
      GoRoute(
        path: RoutePaths.itemFormNew,
        name: RouteNames.itemFormNew,
        builder: (context, state) => const ItemFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.itemFormEdit,
        name: RouteNames.itemFormEdit,
        builder: (context, state) =>
            ItemFormScreen(itemId: state.pathParameters['itemId']!),
      ),
    ],
  ),
];
