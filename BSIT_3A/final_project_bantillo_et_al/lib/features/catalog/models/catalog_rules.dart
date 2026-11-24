// Browse rules in plain Dart (no widgets, no Supabase) so they can be unit
// tested (customer redesign, Phase 1):
//   * BrowseCategory  the icon row: Gowns, Long Gowns, Suits, Bearer, Kids,
//                     Adult; each one sets the type or age-group filter
//   * PriceRange      the price chips in the filter sheet
//   * AvailabilityTag the small tag on product cards
//
// OWNER: Member 1.

import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// One shortcut in the category row.
enum BrowseCategory {
  /// Type gown.
  gowns('Gowns', type: ItemType.gown),

  /// Type long gown.
  longGowns('Long Gowns', type: ItemType.longGown),

  /// Type suit.
  suits('Suits', type: ItemType.suit),

  /// Type bearer.
  bearer('Bearer', type: ItemType.bearer),

  /// Age group kids.
  kids('Kids', ageGroup: AgeGroup.kids),

  /// Age group adult.
  adult('Adult', ageGroup: AgeGroup.adult);

  const BrowseCategory(this.label, {this.type, this.ageGroup});

  /// Text under the icon.
  final String label;

  /// The type this category filters on (type categories only).
  final ItemType? type;

  /// The age group this category filters on (age categories only).
  final AgeGroup? ageGroup;

  /// True when [filter] already has this category switched on.
  bool isSelectedIn(ItemFilter filter) =>
      type != null ? filter.type == type : filter.ageGroup == ageGroup;

  /// Tapping a category turns it on, or off again if it was on. Type and
  /// age categories combine (e.g. Suits + Kids).
  ItemFilter toggleIn(ItemFilter filter) {
    if (type != null) {
      return isSelectedIn(filter)
          ? filter.copyWith(clearType: true)
          : filter.copyWith(type: type);
    }
    return isSelectedIn(filter)
        ? filter.copyWith(clearAgeGroup: true)
        : filter.copyWith(ageGroup: ageGroup);
  }
}

/// Price chips in the filter sheet.
enum PriceRange {
  /// Below 1,500.
  under1500('Under ₱1,500', null, 1499.99),

  /// 1,500 to 3,000.
  from1500To3000('₱1,500 – ₱3,000', 1500, 3000),

  /// 3,000 to 5,000.
  from3000To5000('₱3,000 – ₱5,000', 3000, 5000),

  /// Above 5,000.
  over5000('Over ₱5,000', 5000.01, null);

  const PriceRange(this.label, this.min, this.max);

  /// Chip text.
  final String label;

  /// Lowest price in the range (null = no lower limit).
  final double? min;

  /// Highest price in the range (null = no upper limit).
  final double? max;

  /// The range matching [filter]'s prices, or null for "Any price".
  static PriceRange? of(ItemFilter filter) {
    for (final range in values) {
      if (range.min == filter.minPrice && range.max == filter.maxPrice) {
        return range;
      }
    }
    return null;
  }
}

/// The small tag on a product card.
enum AvailabilityTag {
  /// The customer filtered by event date and this item is free then.
  availableOnYourDate('Available on your date'),

  /// Most of the next [AvailabilityRules.lookAheadDays] days are booked.
  fewDatesLeft('Few dates left');

  const AvailabilityTag(this.label);

  /// Tag text.
  final String label;
}

/// When to show which tag.
abstract final class AvailabilityRules {
  /// How far ahead "Few dates left" looks.
  static const int lookAheadDays = 30;

  /// "Few dates left" when at least this many of those days are booked
  /// (half of the month).
  static const int fewDatesThreshold = 15;

  /// The tag for an item, or null for no tag. Results of a date search
  /// are all free on that date, so they get "Available on your date".
  static AvailabilityTag? tagFor({
    required bool searchedByDate,
    required int busyDays,
  }) {
    if (searchedByDate) return AvailabilityTag.availableOnYourDate;
    if (busyDays >= fewDatesThreshold) return AvailabilityTag.fewDatesLeft;
    return null;
  }
}
