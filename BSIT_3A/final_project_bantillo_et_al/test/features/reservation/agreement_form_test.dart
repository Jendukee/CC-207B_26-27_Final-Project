// Unit tests for the e-contract (customer redesign, Phase 2): the typed
// signature must match the full name, the optional accessory size rows,
// and what is saved in bookings.terms_snapshot.
// Run with: flutter test test/features/reservation

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

AgreementForm _form({List<String> inclusions = const ['Petticoat']}) =>
    AgreementForm(
      fullName: 'Ana Cruz',
      phone: '09171234567',
      item: Item(
        id: 'i1',
        name: 'Ivory Ball Gown',
        type: ItemType.gown,
        ageGroup: AgeGroup.adult,
        size: 'M',
        price: 3500,
        inclusions: inclusions,
      ),
      eventDate: DateTime(2026, 12, 24),
      paymentOption: PaymentOption.half,
      method: PlannedPaymentMethod.gcash,
      waist: 28,
    );

void main() {
  group('signature name match', () {
    test('ignores case and extra spaces', () {
      expect(AgreementRules.nameMatches('ana cruz', 'Ana Cruz'), isTrue);
      expect(AgreementRules.nameMatches('  ANA   CRUZ ', 'Ana Cruz'), isTrue);
      expect(AgreementRules.nameMatches('Ana  Cruz', ' Ana Cruz'), isTrue);
    });

    test('rejects a different or empty name', () {
      expect(AgreementRules.nameMatches('Ana', 'Ana Cruz'), isFalse);
      expect(AgreementRules.nameMatches('Ana Cruzz', 'Ana Cruz'), isFalse);
      expect(AgreementRules.nameMatches('', ''), isFalse);
      expect(AgreementRules.nameMatches('   ', 'Ana Cruz'), isFalse);
    });

    test('validator messages', () {
      expect(
        AgreementRules.validateSignature('', 'Ana Cruz'),
        'Type your full name to sign.',
      );
      expect(
        AgreementRules.validateSignature('Maria', 'Ana Cruz'),
        'Type your full name exactly as entered above.',
      );
      expect(AgreementRules.validateSignature('ana cruz', 'Ana Cruz'), isNull);
    });
  });

  group('form rows', () {
    test('dates, payment and balance are filled in', () {
      final rows = Map.fromEntries(
        _form().rows().map((r) => MapEntry(r.$1, r.$2)),
      );
      expect(rows['Pick-up date'], 'Dec 23, 2026');
      expect(rows['Return date'], 'Dec 25, 2026');
      expect(rows['Down payment'], '50% reservation fee: ₱1,750.00 via GCash');
      expect(rows['Balance'], '₱1,750.00');
      expect(rows['Fitting date'], 'To be arranged with the shop');
      expect(rows['Waist'], '28 in');
    });

    test('shoe and long sleeves sizes appear only when included', () {
      List<String> labels(AgreementForm f) => [for (final r in f.rows()) r.$1];
      expect(labels(_form()), isNot(contains('Shoes size')));
      expect(labels(_form()), isNot(contains('Long sleeves size')));
      final withBoth = _form(inclusions: ['Shoes', 'Long sleeves']);
      expect(
        labels(withBoth),
        containsAll(['Shoes size', 'Long sleeves size']),
      );
    });
  });

  test('snapshot keeps the exact terms, shop details and form', () {
    final snapshot = _form().toSnapshot(
      signedName: ' Ana Cruz ',
      signedAt: DateTime.utc(2026, 11, 24, 3),
    );
    expect(snapshot['version'], RentalTerms.version);
    expect(snapshot['terms'], RentalTerms.items);
    expect(snapshot['signed_name'], 'Ana Cruz');
    expect((snapshot['shop'] as Map)['gcash'], ShopContact.gcash);
    expect(snapshot['accessories'], ['Petticoat']);
    expect((snapshot['rows'] as List).first, {
      'label': 'Full name',
      'value': 'Ana Cruz',
    });
  });
}
