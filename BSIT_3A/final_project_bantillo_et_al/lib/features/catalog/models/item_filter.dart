// Search/filter options for the Browse screen. Private to the catalog
// feature (other features should not import it).
//
// OWNER: Member 1. Add or change fields as you build the filters.

import 'package:orange150_rental/shared/models/item.dart';

/// Criteria passed to CatalogService.searchItems.
class ItemFilter {
  /// Creates a filter. Every field is optional; empty means "any".
  const ItemFilter({
    this.query = '',
    this.type,
    this.ageGroup,
    this.size,
    this.maxPrice,
    this.eventDate,
  });

  /// Free-text search on name/description.
  final String query;

  /// Gown or suit.
  final ItemType? type;

  /// Kids or adult.
  final AgeGroup? ageGroup;

  /// Size label.
  final String? size;

  /// Upper price limit in pesos.
  final double? maxPrice;

  /// Only show items free on this event date.
  final DateTime? eventDate;
}
