// Widget test for ProductCard (Browse grid): with the longest content
// (2-line name and the longest badge) the card must fit its grid cell on a
// 360 px phone without overflowing. Flutter reports any overflow as a test
// failure. The cell size comes from productGridDelegate, as in the app.
// Run with: flutter test test/features/catalog

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/widgets/product_card.dart';
import 'package:orange150_rental/features/catalog/widgets/product_grid_skeleton.dart';
import 'package:orange150_rental/shared/models/item.dart';

void main() {
  testWidgets('fits a 2-column cell on a 360 px phone', (tester) async {
    const item = Item(
      id: 'i1',
      name: 'Maroon Filipiniana Terno with Butterfly Sleeves and Beading',
      type: ItemType.longGown,
      ageGroup: AgeGroup.adult,
      size: 'M',
      price: 12500,
    );

    // 360 px screen minus 20 px padding each side = 320 px grid.
    final delegate =
        productGridDelegate(320) as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    const cardWidth = (320 - 12) / 2; // one 12 px gap between 2 columns
    final cardHeight = cardWidth / delegate.childAspectRatio;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: const ProductCard(
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
    expect(find.text('AVAILABLE ON YOUR DATE'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow

    // The long badge stays inside the card (it wraps instead).
    final badge = tester.getRect(find.text('AVAILABLE ON YOUR DATE'));
    final card = tester.getRect(find.byType(ProductCard));
    expect(badge.right <= card.right, isTrue);
  });

  test('grid columns follow the design breakpoints', () {
    expect(productGridColumns(320), 2);
    expect(productGridColumns(700), 3);
    expect(productGridColumns(1000), 4);
  });
}

void _noop() {}
