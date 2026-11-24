// Unit tests for the Browse rules (customer redesign, Phase 1): category
// toggles, price ranges, availability tags and the filter badge count.
// Run with: flutter test test/features/catalog

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/shared/models/item.dart';

void main() {
  group('BrowseCategory', () {
    test('tapping a type category turns it on, tapping again turns it off', () {
      final on = BrowseCategory.longGowns.toggleIn(const ItemFilter());
      expect(on.type, ItemType.longGown);
      final off = BrowseCategory.longGowns.toggleIn(on);
      expect(off.type, isNull);
    });

    test('type and age categories combine', () {
      var filter = BrowseCategory.suits.toggleIn(const ItemFilter());
      filter = BrowseCategory.kids.toggleIn(filter);
      expect(filter.type, ItemType.suit);
      expect(filter.ageGroup, AgeGroup.kids);
      expect(BrowseCategory.suits.isSelectedIn(filter), isTrue);
      expect(BrowseCategory.adult.isSelectedIn(filter), isFalse);
    });
  });

  group('PriceRange', () {
    test('of() finds the chip matching the filter prices', () {
      final filter = const ItemFilter().copyWith(
        minPrice: 1500,
        maxPrice: 3000,
      );
      expect(PriceRange.of(filter), PriceRange.from1500To3000);
      expect(PriceRange.of(const ItemFilter()), isNull);
    });

    test('open-ended ranges', () {
      final over = const ItemFilter().copyWith(minPrice: 5000.01);
      expect(PriceRange.of(over), PriceRange.over5000);
    });
  });

  group('AvailabilityRules.tagFor', () {
    test('date search results are available on that date', () {
      expect(
        AvailabilityRules.tagFor(searchedByDate: true, busyDays: 0),
        AvailabilityTag.availableOnYourDate,
      );
    });

    test('few dates left from 15 busy days in the next 30', () {
      expect(
        AvailabilityRules.tagFor(searchedByDate: false, busyDays: 15),
        AvailabilityTag.fewDatesLeft,
      );
      expect(
        AvailabilityRules.tagFor(searchedByDate: false, busyDays: 14),
        isNull,
      );
    });
  });

  test('activeCount and reset', () {
    final filter = const ItemFilter(
      query: 'ivory',
    ).copyWith(type: ItemType.gown, size: 'M', minPrice: 1500, maxPrice: 3000);
    expect(filter.activeCount, 3); // type, size, price (search not counted)
    final reset = filter.reset();
    expect(reset.activeCount, 0);
    expect(reset.query, 'ivory');
  });
}
