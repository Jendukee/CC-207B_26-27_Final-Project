// Favorites data access (customer redesign 2, Phase 1). Table: favorites
// (migration 0014). RLS lets each signed-in customer read, add and remove
// only their own rows; guests never call this.
//
// [FavoritesApi] is the small interface the FavoritesController uses, so
// tests can pass a fake instead of Supabase.
//
// OWNER: Member 1.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// What the app needs from the favorites table.
abstract interface class FavoritesApi {
  /// The ids of the signed-in customer's saved items.
  Future<Set<String>> myFavoriteIds();

  /// Saves [itemId] (no error if it is already saved).
  Future<void> add(String itemId);

  /// Removes [itemId] (no error if it was not saved).
  Future<void> remove(String itemId);

  /// The saved items, newest first, without retired items.
  Future<List<Item>> myFavoriteItems();
}

/// [FavoritesApi] backed by Supabase.
class FavoritesService implements FavoritesApi {
  /// Uses [client], or the app's Supabase client.
  FavoritesService({this.client});

  /// A client for tests; null uses the app's client.
  final SupabaseClient? client;

  // Read lazily, so creating the service never needs Supabase (tests).
  SupabaseClient get _db => client ?? SupabaseService.client;

  String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to save favorites.');
    return id;
  }

  @override
  Future<Set<String>> myFavoriteIds() async {
    _userId; // RLS returns only own rows; this just checks sign-in.
    final rows = await _db.from('favorites').select('item_id');
    return {for (final row in rows) row['item_id'] as String};
  }

  @override
  Future<void> add(String itemId) async {
    // ON CONFLICT DO NOTHING: saving twice is not an error, and it needs
    // only the INSERT grant (there is no UPDATE grant on favorites).
    await _db
        .from('favorites')
        .upsert(
          {'user_id': _userId, 'item_id': itemId},
          onConflict: 'user_id,item_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> remove(String itemId) async {
    await _db
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('item_id', itemId);
  }

  @override
  Future<List<Item>> myFavoriteItems() async {
    _userId;
    // Each favorite with its item (foreign key favorites.item_id -> items).
    final rows = await _db
        .from('favorites')
        .select('created_at, item:items(*)')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        if (row['item'] case final Map<String, dynamic> item)
          // Retired items are no longer offered, so they are hidden here.
          if (item['condition'] != ItemCondition.retired.dbValue)
            Item.fromMap(item),
    ];
  }
}
