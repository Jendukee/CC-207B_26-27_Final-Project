// Customer redesign 2, Phase 1 shared widgets:
//   * BrandAppBar: the "Orange 150" mark before the title, the back arrow
//     first, and the mark is not a button
//   * BookingStatusCard: chip, status in words, next step, deadline and the
//     timeline, without overflow on a 360 px phone
//   * the customer and staff status wording
// Run with: flutter test test/core

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/core/widgets/booking_status_card.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/features/my_bookings/models/customer_status_text.dart';
import 'package:orange150_rental/features/shop_bookings/models/staff_status_text.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

Booking _booking(String status) => Booking.fromMap({
  'id': 'b1',
  'reference_no': 'O150-1',
  'customer_id': 'c1',
  'status': status,
  'payment_option': 'half',
  'total_amount': 1750,
  'amount_paid': status == 'pending' ? 0 : 875,
  'pickup_date': '2026-12-09',
  'event_date': '2026-12-10',
  'return_date': '2026-12-11',
  'expires_at': DateTime(2026, 12, 8, 23, 59).toUtc().toIso8601String(),
});

void main() {
  testWidgets('BrandAppBar: back arrow, then the mark, then the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('home')),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(appBar: BrandAppBar(title: 'Item details')),
      ),
    );
    await tester.pumpAndSettle();

    // The header reads "Orange 150" (the mark), then the title.
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Orange 150')), findsOneWidget);
    semantics.dispose();
    expect(find.text('Item details'), findsOneWidget);
    final back = tester.getTopLeft(find.byType(BackButton));
    final mark = tester.getTopLeft(find.byType(BrandLogo));
    final title = tester.getTopLeft(find.text('Item details'));
    expect(back.dx < mark.dx && mark.dx < title.dx, isTrue);
    // The mark has no tap action.
    expect(
      find.ancestor(of: find.byType(BrandLogo), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('BookingStatusCard fits a 360 px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final b = _booking('pending');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookingStatusCard(
              status: BookingStatus.pending,
              statusText: CustomerStatusText.words(BookingStatus.pending),
              nextStep: CustomerStatusText.nextStep(b, DateTime(2026, 12, 1)),
              deadline: b.expiresAt,
              steps: [
                (label: 'Requested', date: DateTime(2026, 11, 24, 10)),
                (label: 'Reserved', date: null),
                (label: 'Picked up', date: null),
                (label: 'Returned', date: null),
              ],
              action: FilledButton(
                onPressed: () {},
                child: const Text('How to pay'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Booking status'), findsOneWidget);
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.textContaining('Payment deadline:'), findsOneWidget);
    expect(find.text('Not yet'), findsNWidgets(3));
    expect(find.text('How to pay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('customer next step says how much, by when, and why', () {
    final text = CustomerStatusText.nextStep(
      _booking('pending'),
      DateTime(2026, 12, 1),
    );
    expect(text, startsWith('Pay ₱875.00 by '));
    expect(text, endsWith('to confirm your reservation.'));
  });

  test('staff wording for every status', () {
    for (final status in BookingStatus.values) {
      expect(StaffStatusText.words(status), isNotEmpty);
      expect(
        StaffStatusText.nextStep(_booking('reserved'), status),
        isNotEmpty,
      );
    }
    expect(
      StaffStatusText.nextStep(_booking('reserved'), BookingStatus.reserved),
      contains('Collect the balance of ₱875.00'),
    );
  });
}
