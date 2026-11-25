// Staff dashboard design layout checks, no Supabase:
//   * the gradient hero with greeting, date, "View calendar" and five tiles
//     fits a 360 px phone and a 1100 px laptop without overflow
//   * the BrandSidebar shows the logo, every item, the selected item and
//     the account footer, and a tap selects the item
// Run with: flutter test test/features/shop_dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/core/widgets/brand_sidebar.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_hero.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_summary_tile.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
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

Widget _hero({required VoidCallback onViewCalendar}) => SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: DashboardHero(
    greeting: 'Hi, Pearl Batumbakal',
    dateLine: 'Today is Nov 24, 2026',
    onViewCalendar: onViewCalendar,
    tiles: [
      for (final section in DashboardSection.values)
        DashboardSummaryTile(
          section: section,
          future: Future.value(const <DashboardBooking>[]),
          onView: () {},
        ),
    ],
  ),
);

void main() {
  for (final size in const [Size(360, 1200), Size(1100, 800)]) {
    testWidgets('hero fits ${size.width.toInt()} px', (tester) async {
      var opened = false;
      await _pump(tester, size, _hero(onViewCalendar: () => opened = true));
      await tester.pump();

      expect(find.text('Hi, Pearl Batumbakal'), findsOneWidget);
      expect(find.text('Today is Nov 24, 2026'), findsOneWidget);
      expect(find.byType(DashboardSummaryTile), findsNWidgets(5));
      expect(find.text('0'), findsNWidgets(5));
      expect(tester.takeException(), isNull); // no overflow

      await tester.tap(find.text('View calendar'));
      expect(opened, isTrue);
    });
  }

  testWidgets('sidebar: items, selection, account footer', (tester) async {
    var selected = 0;
    await _pump(
      tester,
      const Size(1100, 800),
      StatefulBuilder(
        builder: (context, setState) => Align(
          alignment: Alignment.centerLeft,
          child: BrandSidebar(
            items: const [
              (
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              (
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month,
                label: 'Calendar',
              ),
            ],
            selectedIndex: selected,
            onSelect: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );

    expect(find.text('Orange 150'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('MANAGEMENT'), findsOneWidget);
    expect(find.text('Staff account'), findsOneWidget);
    expect(find.byIcon(Icons.dashboard), findsOneWidget); // selected icon

    await tester.tap(find.text('Calendar'));
    await tester.pump();
    expect(selected, 1);
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    // 48 px targets.
    expect(tester.getSize(find.byType(InkWell).first).height, 48);
    expect(tester.takeException(), isNull);
  });
}
