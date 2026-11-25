// "Today at a glance" and "New requests" (dashboard design), no Supabase:
//   * a glance card: friendly empty line, "View more" opens the list, a
//     booking row opens the booking, an error shows Retry
//   * the requests panel: count, rows with the Pending pill, footer link
//   * both fit a 360 px phone without overflow (long names included)
// Run with: flutter test test/features/shop_dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_glance_card.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_requests_panel.dart';

DashboardBooking _booking(String id, String status) =>
    DashboardBooking.fromMap({
      'id': id,
      'reference_no': 'O150-261124-$id',
      'customer_id': 'c1',
      'status': status,
      'payment_option': 'half',
      'total_amount': 1750,
      'amount_paid': 0,
      'pickup_date': '2026-11-25',
      'event_date': '2026-11-26',
      'return_date': '2026-11-27',
      'created_at': '2026-11-24T08:47:00Z',
      'customer': {'full_name': 'Maria Clara Santos de la Cruz Batumbakal'},
    });

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final now = DateTime(2026, 11, 24, 10);

  testWidgets('glance card: empty line and View more', (tester) async {
    var opened = 0;
    await _pump(
      tester,
      DashboardGlanceCard(
        section: DashboardSection.pickupsToday,
        future: Future.value(const <DashboardBooking>[]),
        now: now,
        onOpenList: () => opened++,
        onOpenBooking: (_) {},
        onRetry: () {},
      ),
    );
    await tester.pump();
    expect(find.text(DashboardSection.pickupsToday.title), findsOneWidget);
    expect(
      find.text('Your next confirmed pick-up will appear here.'),
      findsOneWidget,
    );
    await tester.tap(find.text('View more'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('glance card: count and booking rows', (tester) async {
    String? openedId;
    await _pump(
      tester,
      DashboardGlanceCard(
        section: DashboardSection.overdueReturns,
        future: Future.value([
          _booking('A1', 'rented_out'),
          _booking('B2', 'rented_out'),
        ]),
        now: DateTime(2026, 11, 30),
        onOpenList: () {},
        onOpenBooking: (id) => openedId = id,
        onRetry: () {},
      ),
    );
    await tester.pump();
    expect(find.text('2 bookings'), findsOneWidget);
    expect(find.textContaining('days late'), findsNWidgets(2));
    await tester.tap(find.textContaining('O150-261124-B2'));
    expect(openedId, 'B2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('glance card: error shows Retry', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      DashboardGlanceCard(
        section: DashboardSection.returnsToday,
        // ..ignore(): the error is expected; the card still receives it.
        future: Future<List<DashboardBooking>>.error(
          const DashboardException('No internet connection.'),
        )..ignore(),
        now: now,
        onOpenList: () {},
        onOpenBooking: (_) {},
        onRetry: () => retried++,
      ),
    );
    await tester.pump();
    expect(find.text('No internet connection.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('requests panel: count, Pending pills, footer link', (
    tester,
  ) async {
    var listOpened = 0;
    await _pump(
      tester,
      DashboardRequestsPanel(
        future: Future.value([
          _booking('A1', 'pending'),
          _booking('B2', 'pending'),
          _booking('C3', 'pending'),
          _booking('D4', 'pending'),
        ]),
        now: now,
        onOpenList: () => listOpened++,
        onOpenBooking: (_) {},
        onRetry: () {},
      ),
    );
    await tester.pump();
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(4));
    expect(find.textContaining('Nov 24, 2026 · '), findsNWidgets(4));
    await tester.tap(find.text('View all booking requests →'));
    expect(listOpened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requests panel: empty', (tester) async {
    await _pump(
      tester,
      DashboardRequestsPanel(
        future: Future.value(const <DashboardBooking>[]),
        now: now,
        onOpenList: () {},
        onOpenBooking: (_) {},
        onRetry: () {},
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('No new requests since yesterday.'), findsOneWidget);
  });
}
