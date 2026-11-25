// Calendar filter design: the white segment boxes (Month / Week and the
// categories), no Supabase:
//   * the chosen option is drawn filled (maroon) or tinted (pink) and is
//     announced as selected; a tap reports the value
//   * 48 px targets, no overflow on a 360 px phone
// Run with: flutter test test/features/shop_calendar

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_segment_group.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Color? _fill(WidgetTester tester, String label) => tester
    .widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    )
    .color;

void main() {
  testWidgets('filled: chosen is maroon, tap reports the value', (
    tester,
  ) async {
    String? tapped;
    await _pump(
      tester,
      CalendarSegmentGroup<String>(
        options: const [('month', 'Month'), ('week', 'Week')],
        selected: 'month',
        onSelected: (v) => tapped = v,
      ),
    );
    expect(_fill(tester, 'Month'), AppColors.maroon);
    expect(_fill(tester, 'Week'), Colors.transparent);

    final semantics = tester.ensureSemantics();
    // Screen readers hear "Month, selected".
    expect(
      tester.getSemantics(find.text('Month')),
      matchesSemantics(
        label: 'Month',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();

    await tester.tap(find.text('Week'));
    expect(tapped, 'week');
    // 44 px option inside the 4 px frame: a 48+ px target.
    expect(
      tester.getSize(find.byType(CalendarSegmentGroup<String>)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('tint: chosen is light pink; fits 360 px when scrolling', (
    tester,
  ) async {
    await _pump(
      tester,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CalendarSegmentGroup<int?>(
          style: SegmentStyle.tint,
          options: const [
            (null, 'All'),
            (1, 'Gown'),
            (2, 'Long gown'),
            (3, 'Suit'),
            (4, 'Bearer'),
          ],
          selected: null,
          onSelected: (_) {},
        ),
      ),
    );
    expect(_fill(tester, 'All'), AppColors.tintPink);
    expect(tester.takeException(), isNull);
  });
}
