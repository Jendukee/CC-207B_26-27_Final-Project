// Browse screen: the guest-friendly home of the customer app.
// Will show a searchable grid of gowns and suits with filters (type, kids/adult,
// size, price, event date) using CatalogService.searchItems, and open
// ItemDetails via RouteNames.itemDetails.
//
// OWNER: Member 1. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Browse" screen (see the file header for the plan).
class BrowseScreen extends StatelessWidget {
  /// Creates the "Browse" screen.
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO: Member 1 builds this',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
