// Item details screen: photos, price, size, inclusions and description of one item.
// Will show an availability calendar (table_calendar) fed by the
// get_blocked_dates RPC, and a Reserve button that pushes RouteNames.reserveDates
// (guests are sent to Login by the auth guard).
//
// OWNER: Member 1. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Item Details" screen (see the file header for the plan).
class ItemDetailsScreen extends StatelessWidget {
  /// Creates the "Item Details" screen for the given [itemId].
  const ItemDetailsScreen({super.key, required this.itemId});

  /// Path parameter from the route (see catalog_routes.dart).
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'TODO: Member 1 builds this\n(itemId: $itemId)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
