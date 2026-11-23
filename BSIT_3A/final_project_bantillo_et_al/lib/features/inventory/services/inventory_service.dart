// Staff inventory management: add/edit items, upload photos, change the
// physical condition. Tables/buckets: items (write), item-photos bucket.
//
// OWNER: Member 1. Every method is a stub that throws UnimplementedError
// until Member 1 implements it.

import 'dart:typed_data';

import 'package:orange150_rental/shared/models/item.dart';

/// Writes inventory data. RLS only allows staff/owner to write items.
class InventoryService {
  /// All items, optionally including retired ones.
  Future<List<Item>> listItems({bool includeRetired = false}) =>
      throw UnimplementedError('TODO(Member 1): list items for staff');

  /// Inserts [item] and returns the saved row.
  Future<Item> createItem(Item item) =>
      throw UnimplementedError('TODO(Member 1): insert item');

  /// Updates [item] and returns the saved row.
  Future<Item> updateItem(Item item) =>
      throw UnimplementedError('TODO(Member 1): update item');

  /// Changes only the physical condition of [itemId].
  Future<void> setCondition(String itemId, ItemCondition condition) =>
      throw UnimplementedError('TODO(Member 1): update item condition');

  /// Uploads a photo to the item-photos bucket and returns its public URL.
  Future<String> uploadPhoto({
    required String itemId,
    required Uint8List bytes,
    required String fileName,
  }) =>
      throw UnimplementedError('TODO(Member 1): upload to item-photos');
}
