// Inventory list (staff): every item with its photo, price and physical condition
// (available / cleaning-repair / retired) shown with a text label.
// Will let staff search, filter by condition and open ItemForm to add or edit.
//
// OWNER: Member 1. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Inventory" screen (see the file header for the plan).
class InventoryListScreen extends StatelessWidget {
  /// Creates the "Inventory" screen.
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
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
