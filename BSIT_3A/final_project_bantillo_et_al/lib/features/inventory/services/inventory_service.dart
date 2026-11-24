// Staff inventory management: add/edit items, upload photos, change the
// physical condition. Tables/buckets: items (write), item-photos bucket.
//
// OWNER: Member 1.

import 'dart:math';
import 'dart:typed_data';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes inventory data. RLS only allows staff/owner to write items.
class InventoryService {
  /// All items, optionally including retired ones.
  Future<List<Item>> listItems({bool includeRetired = false}) async {
    var query = SupabaseService.client.from('items').select();
    if (!includeRetired) {
      query = query.neq('condition', ItemCondition.retired.dbValue);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((row) => Item.fromMap(row)).toList();
  }

  /// Inserts [item] and returns the saved row.
  Future<Item> createItem(Item item) async {
    final row = await SupabaseService.client
        .from('items')
        .insert(item.toMap())
        .select()
        .single();
    return Item.fromMap(row);
  }

  /// Updates [item] and returns the saved row.
  Future<Item> updateItem(Item item) async {
    final row = await SupabaseService.client
        .from('items')
        .update(item.toMap())
        .eq('id', item.id)
        .select()
        .single();
    return Item.fromMap(row);
  }

  /// Changes only the physical condition of [itemId].
  Future<void> setCondition(String itemId, ItemCondition condition) async {
    await SupabaseService.client
        .from('items')
        .update({'condition': condition.dbValue})
        .eq('id', itemId)
        .select('id')
        .single();
  }

  /// Uploads a photo to the item-photos bucket and returns its public URL.
  Future<String> uploadPhoto({
    required String itemId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(itemId)) {
      throw ArgumentError.value(
        itemId,
        'itemId',
        'Must be a non-empty path-safe identifier.',
      );
    }

    final fileNameOnly = fileName.split(RegExp(r'[/\\]')).last;
    final extensionStart = fileNameOnly.lastIndexOf('.');
    final extension = extensionStart > 0
        ? fileNameOnly.substring(extensionStart + 1).toLowerCase()
        : '';
    final safeExtension =
        RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '';

    final random = Random.secure();
    final uniqueName = List<int>.generate(
      16,
      (_) => random.nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final objectName =
        safeExtension.isEmpty ? uniqueName : '$uniqueName.$safeExtension';
    final storagePath = '$itemId/$objectName';

    await SupabaseService.client.storage.from('item-photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(safeExtension),
            upsert: false,
          ),
        );

    return SupabaseService.client.storage
        .from('item-photos')
        .getPublicUrl(storagePath);
  }

  static String _contentTypeFor(String extension) => switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        _ => 'application/octet-stream',
      };
}
