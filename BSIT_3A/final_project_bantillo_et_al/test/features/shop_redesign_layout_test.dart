// Shop-side redesign (Phase 2) layout checks on a 360 px phone, no Supabase:
//   * the staff booking card (photo, customer, dates, chip, paid / balance)
//   * the inventory grid card (condition chip, price, Edit)
//   * a dashboard summary tile (count, label, View)
//   * the sticky bar with outlined secondary buttons above the main one
// Each must lay out without overflow (long names included).
// Run with: flutter test test/features/shop_redesign_layout_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/inventory/widgets/inventory_item_card.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';
import 'package:orange150_rental/features/shop_bookings/widgets/shop_booking_card.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_summary_tile.dart';
import 'package:orange150_rental/shared/models/item.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

final Map<String, dynamic> _row = {
  'id': 'b1',
  'reference_no': 'O150-0012',
  'customer_id': 'c1',
  'status': 'reserved',
  'payment_option': 'half',
  'total_amount': 1750,
  'amount_paid': 875,
  'pickup_date': '2026-12-09',
  'event_date': '2026-12-10',
  'return_date': '2026-12-11',
  'customer': {'full_name': 'Maria Clara Santos de la Cruz', 'phone': null},
  'booking_items': [
    {
      'price': 1750,
      'item': {
        'id': 'i1',
        'name': 'Ivory Ball Gown with a Very Long Cathedral Train',
        'type': 'gown',
        'size': 'M',
        'inclusions': <String>[],
        'photo_urls': <String>[],
      },
    },
  ],
};

void main() {
  testWidgets('staff booking card fits 360 px', (tester) async {
    await _pump(
      tester,
      ShopBookingCard(booking: ShopBooking.fromMap(_row), onTap: () {}),
    );
    expect(find.text('Ref O150-0012'), findsOneWidget);
    expect(find.text('Reserved'), findsOneWidget);
    expect(find.textContaining('Balance ₱875.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory card fits a 2-column cell', (tester) async {
    const item = Item(
      id: 'i1',
      name: 'Classic Black Tuxedo with Satin Lapels and Vest',
      type: ItemType.suit,
      ageGroup: AgeGroup.adult,
      size: '40R',
      price: 2500,
      condition: ItemCondition.cleaningRepair,
    );
    await _pump(
      tester,
      CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid.builder(
                gridDelegate: inventoryGridDelegate(
                  constraints.crossAxisExtent,
                ),
                itemCount: 2,
                itemBuilder: (_, _) =>
                    InventoryItemCard(item: item, onTap: () {}),
              ),
            ),
          ),
        ],
      ),
    );
    expect(find.text('Cleaning / Repair'), findsWidgets);
    expect(find.text('Edit'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard summary tile shows count, label and View', (
    tester,
  ) async {
    final future = Future.value([
      DashboardBooking.fromMap(_row),
      DashboardBooking.fromMap(_row),
    ]);
    await _pump(
      tester,
      Center(
        child: SizedBox(
          width: 160,
          child: DashboardSummaryTile(
            section: DashboardSection.pickupsToday,
            future: future,
            onView: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(find.text(DashboardSection.pickupsToday.title), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sticky bar: secondary buttons above one main button', (
    tester,
  ) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: StickyActionBar(
          leading: const Text('Balance'),
          secondary: [
            OutlinedButton(
              onPressed: () {},
              child: const Text('Mark picked up'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Cancel booking'),
            ),
          ],
          action: FilledButton(
            onPressed: () {},
            child: const Text('Record balance payment'),
          ),
        ),
      ),
    );
    final secondary = tester.getTopLeft(find.text('Mark picked up'));
    final main = tester.getTopLeft(find.text('Record balance payment'));
    expect(secondary.dy < main.dy, isTrue);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
