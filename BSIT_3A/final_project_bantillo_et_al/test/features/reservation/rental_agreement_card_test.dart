// Widget test for the checkout's RentalAgreementCard (Phase 2): on a 360 px
// phone it shows the shop header, the filled-in form, the free
// accessories, the terms and the signature fields without overflowing;
// shoe / long sleeves sizes appear only when they come with the item; and
// the signature field rejects a name that does not match.
// Run with: flutter test test/features/reservation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';
import 'package:orange150_rental/features/reservation/models/payment_plan.dart';
import 'package:orange150_rental/features/reservation/widgets/rental_agreement_card.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

Future<TextEditingController> _pump(
  WidgetTester tester, {
  required List<String> inclusions,
}) async {
  final signature = TextEditingController();
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
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            child: RentalAgreementCard(
              form: form,
              facebook: TextEditingController(),
              note: TextEditingController(),
              shoeSize: TextEditingController(),
              longSleevesSize: TextEditingController(),
              signature: signature,
              agreed: false,
              onAgreedChanged: (_) {},
              onChanged: () {},
            ),
          ),
        ),
      ),
    ),
  );
  return signature;
}

void main() {
  testWidgets('shows the form and terms on a 360 px phone', (tester) async {
    await _pump(tester, inclusions: ['Bow tie', 'Shoes']);

    expect(find.text(ShopContact.name), findsOneWidget);
    expect(find.text('Bow tie'), findsOneWidget);
    expect(find.text('Shoes size (optional)'), findsOneWidget);
    expect(find.text('Long sleeves size (optional)'), findsNothing);
    expect(find.text('Terms and conditions'), findsOneWidget);
    expect(find.text('Not signed yet.'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('signature must match the full name', (tester) async {
    await _pump(tester, inclusions: const []);
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
  });
}
