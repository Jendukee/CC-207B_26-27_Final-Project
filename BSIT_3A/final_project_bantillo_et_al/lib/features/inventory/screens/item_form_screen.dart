// Item form (staff): add a new item or edit an existing one.
// Will have fields for name, type (gown/suit), age group, size, price,
// description, inclusions list, photos (image_picker -> item-photos bucket)
// and physical condition, validated with core/utils/validators.dart.
// `itemId == null` means "Add"; otherwise the item is loaded for editing.
//
// OWNER: Member 1. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Add Item" / "Edit Item" screen.
class ItemFormScreen extends StatelessWidget {
  /// Creates the form. Pass [itemId] to edit, or leave it null to add.
  const ItemFormScreen({super.key, this.itemId});

  /// Item being edited, or null when adding a new item.
  final String? itemId;

  /// True when editing an existing item.
  bool get isEditing => itemId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isEditing
                ? 'TODO: Member 1 builds this\n(itemId: $itemId)'
                : 'TODO: Member 1 builds this',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
