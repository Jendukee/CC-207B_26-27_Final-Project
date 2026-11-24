// Widget tests for the checkout's e-contract:
//   * RentalAgreementCard on a 360 px phone shows the shop header, the
//     filled-in form, the free accessories and the terms without
//     overflowing; shoe / long sleeves sizes appear only when they come
//     with the item; it has NO signature any more (customer redesign 2).
//   * SignAndSubmitFields (the last "Sign and submit" card) shows the
//     explanation, rejects a name that does not match and accepts the
//     same name with other case and spaces.
// Run with: flutter test test/features/reservation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';
import 'package:orange150_rental/features/reservation/widgets/rental_agreement_card.dart';
import 'package:orange150_rental/features/reservation/widgets/sign_and_submit_fields.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

Future<void> _pumpPage(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(child: Form(child: child)),
      ),
    ),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required List<String> inclusions,
}) {
  final form = AgreementForm(
    fullName: 'Ana Cruz',
    phone: '09171234567',
    item: Item(
      id: 'i1',
      name: 'Classic Black Tuxedo',
      type: ItemType.suit,
      ageGroup: AgeGroup.adult,
      size: '40R',
      price: 2500,
      inclusions: inclusions,
    ),
    eventDate: DateTime(2026, 12, 24),
    paymentOption: PaymentOption.half,
    method: PlannedPaymentMethod.cash,
  );
  return _pumpPage(
    tester,
    RentalAgreementCard(
      form: form,
      facebook: TextEditingController(),
      note: TextEditingController(),
      shoeSize: TextEditingController(),
      longSleevesSize: TextEditingController(),
      onChanged: () {},
    ),
  );
}

void main() {
  testWidgets('agreement card: form and terms on a 360 px phone', (
    tester,
  ) async {
    await _pumpCard(tester, inclusions: ['Bow tie', 'Shoes']);

    expect(find.text(ShopContact.name), findsOneWidget);
    expect(find.text('Bow tie'), findsOneWidget);
    expect(find.text('Shoes size (optional)'), findsOneWidget);
    expect(find.text('Long sleeves size (optional)'), findsNothing);
    expect(find.text('Terms and conditions'), findsOneWidget);
    // The signature moved to the last card (customer redesign 2).
    expect(find.text('Type your full name to sign *'), findsNothing);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('sign and submit: explanation and name match', (tester) async {
    final signature = TextEditingController();
    await _pumpPage(
      tester,
      SignAndSubmitFields(
        fullName: 'Ana Cruz',
        signature: signature,
        agreed: false,
        onAgreedChanged: (_) {},
        onChanged: () {},
      ),
    );

    expect(find.text(SignAndSubmitFields.explanation), findsOneWidget);
    expect(find.text('Not signed yet.'), findsOneWidget);

    final field = find.widgetWithText(
      TextFormField,
      'Type your full name to sign *',
    );
    await tester.enterText(field, 'Maria Santos');
    await tester.pump();
    expect(
      find.text('Type your full name exactly as entered above.'),
      findsOneWidget,
    );

    await tester.enterText(field, '  ana   CRUZ ');
    await tester.pump();
    expect(
      find.text('Type your full name exactly as entered above.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign and submit: shows the signing time once signed', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      SignAndSubmitFields(
        fullName: 'Ana Cruz',
        signature: TextEditingController(text: 'Ana Cruz'),
        agreed: true,
        signedAt: DateTime(2026, 11, 24, 10, 30),
        onAgreedChanged: (_) {},
        onChanged: () {},
      ),
    );
    expect(find.textContaining('Signed on'), findsOneWidget);
  });
}
