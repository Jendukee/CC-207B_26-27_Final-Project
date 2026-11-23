// Data access for the customer catalog: search, item details and
// availability. Tables/RPCs: items (read), get_blocked_dates (RPC).
//
// OWNER: Member 1. Every method is a stub that throws UnimplementedError
// until Member 1 implements it.

import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Reads catalog data from Supabase. Guests can call every method.
class CatalogService {
  /// Returns rentable items matching [filter] (excluding retired items).
  Future<List<Item>> searchItems(ItemFilter filter) =>
      throw UnimplementedError('TODO(Member 1): query items with filter');

  /// Returns one item by [itemId].
  Future<Item> getItem(String itemId) =>
      throw UnimplementedError('TODO(Member 1): select one item');

  /// Dates between [from] and [to] when [itemId] is already booked.
  /// Use the get_blocked_dates RPC (it never exposes other customers' data).
  Future<List<DateTime>> getBlockedDates({
    required String itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      throw UnimplementedError('TODO(Member 1): call get_blocked_dates RPC');
}
