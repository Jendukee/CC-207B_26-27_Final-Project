// Search/filter options for the Browse screen. Private to the catalog
// feature (other features should not import it).
//
// Customer redesign: adds a price RANGE (min + max) chosen with chips in
// the filter bottom sheet, and copyWith / activeCount for the sheet and
// the filter badge.
//
// OWNER: Member 1.

import 'package:orange150_rental/shared/models/item.dart';

/// Criteria passed to CatalogService.searchItems.
class ItemFilter {
  /// Creates a filter. Every field is optional; empty means "any".
  const ItemFilter({
    this.query = '',
    this.type,
    this.ageGroup,
    this.size,
    this.minPrice,
    this.maxPrice,
    this.eventDate,
  });

  /// Free-text search on name/description.
  final String query;

  /// Gown, long gown, suit or bearer.
  final ItemType? type;

  /// Kids or adult.
  final AgeGroup? ageGroup;

  /// Size label.
  final String? size;

  /// Lower price limit in pesos (inclusive).
  final double? minPrice;

  /// Upper price limit in pesos (inclusive).
  final double? maxPrice;

  /// Only show items free on this event date.
  final DateTime? eventDate;

  /// How many filters (not counting the search text) are switched on.
  /// Shown as a badge on the filter icon.
  int get activeCount => [
    type,
    ageGroup,
    size,
    minPrice ?? maxPrice,
    eventDate,
  ].where((value) => value != null).length;

  /// Copy with some fields changed. Because null means "keep", use the
  /// clear* flags to remove a filter.
  ItemFilter copyWith({
    String? query,
    ItemType? type,
    bool clearType = false,
    AgeGroup? ageGroup,
    bool clearAgeGroup = false,
    String? size,
    bool clearSize = false,
    double? minPrice,
    double? maxPrice,
    bool clearPrice = false,
    DateTime? eventDate,
    bool clearEventDate = false,
  }) {
    return ItemFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      ageGroup: clearAgeGroup ? null : (ageGroup ?? this.ageGroup),
      size: clearSize ? null : (size ?? this.size),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
    );
  }

  /// The same search text with every filter removed (the sheet's Reset).
  ItemFilter reset() => ItemFilter(query: query);
}
