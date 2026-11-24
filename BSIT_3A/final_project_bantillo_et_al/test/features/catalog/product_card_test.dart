// Widget test for ProductCard (customer redesign, Phase 1): with the
// longest content (2-line name and a tag) the card must fit the grid cell
// of a 360 px wide phone without overflowing. Flutter reports any overflow
// as a test failure.
// Run with: flutter test test/features/catalog

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/widgets/product_card.dart';
import 'package:orange150_rental/shared/models/item.dart';

void main() {
  testWidgets('fits a 2-column cell on a 360 px phone', (tester) async {
    const item = Item(
      id: 'i1',
      name: 'Maroon Filipiniana Terno with Butterfly Sleeves and Beading',
      type: ItemType.gown,
      ageGroup: AgeGroup.adult,
      size: 'M',
      price: 12500,
    );
    // 360 px screen: (360 - 8 padding * 2 - 8 gap) / 2 = 168 px per card,
    // height 168 / 0.46 (the grid's childAspectRatio) = about 365 px.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 168,
              height: 365,
              child: ProductCard(
                item: item,
                onTap: _noop,
                tag: AvailabilityTag.availableOnYourDate,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('₱12,500.00'), findsOneWidget);
    expect(find.text('Available on your date'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow
  });
}

void _noop() {}
