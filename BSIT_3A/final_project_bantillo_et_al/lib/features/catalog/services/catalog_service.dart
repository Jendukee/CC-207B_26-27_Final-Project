// Data access for the customer catalog: search, item details and
// availability. Tables/RPCs: items (read), get_blocked_dates (RPC).
//
// OWNER: Member 1.

import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Reads catalog data from Supabase. Guests can call every method.
class CatalogService {
  /// Returns rentable items matching [filter].
  /// Items undergoing cleaning/repair or retired are excluded.
  Future<List<Item>> searchItems(ItemFilter filter) async {
    final rows = await SupabaseService.client
        .from('items')
        .select()
        .eq('condition', ItemCondition.available.dbValue)
        .order('created_at', ascending: false);

    var items = rows.map((row) => Item.fromMap(row)).toList();

    final query = filter.query.trim().toLowerCase();

    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }).toList();
    }

    if (filter.type != null) {
      items = items.where((item) => item.type == filter.type).toList();
    }

    if (filter.ageGroup != null) {
      items = items
          .where((item) => item.ageGroup == filter.ageGroup)
          .toList();
    }

    if (filter.size != null && filter.size!.trim().isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.size.toLowerCase() == filter.size!.trim().toLowerCase(),
          )
          .toList();
    }

    if (filter.maxPrice != null) {
      items = items.where((item) => item.price <= filter.maxPrice!).toList();
    }

    if (filter.eventDate != null) {
      final eventDate = _dateOnly(filter.eventDate!);
      final from = eventDate.subtract(const Duration(days: 1));
      final to = eventDate.add(const Duration(days: 1));

      final availableItems = <Item>[];

      for (final item in items) {
        final blockedDates = await getBlockedDates(
          itemId: item.id,
          from: from,
          to: to,
        );

        if (blockedDates.isEmpty) {
          availableItems.add(item);
        }
      }

      items = availableItems;
    }

    return items;
  }

  /// Returns one item by [itemId].
  Future<Item> getItem(String itemId) async {
    final row = await SupabaseService.client
        .from('items')
        .select()
        .eq('id', itemId)
        .eq('condition', ItemCondition.available.dbValue)
        .single();

    return Item.fromMap(row);
  }

  /// Dates between [from] and [to] when [itemId] is already booked.
  /// Uses the get_blocked_dates RPC.
  Future<List<DateTime>> getBlockedDates({
    required String itemId,
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await SupabaseService.client.rpc(
      'get_blocked_dates',
      params: {
        'p_item_id': itemId,
        'p_from': _dateString(from),
        'p_to': _dateString(to),
      },
    );

    return (result as List<dynamic>)
        .map((date) => _dateOnly(DateTime.parse(date.toString())))
        .toList();
  }

  /// Removes the time portion from a date.
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Formats a date as YYYY-MM-DD for PostgreSQL.
  String _dateString(DateTime date) {
    final dateOnly = _dateOnly(date);

    final year = dateOnly.year.toString().padLeft(4, '0');
    final month = dateOnly.month.toString().padLeft(2, '0');
    final day = dateOnly.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}