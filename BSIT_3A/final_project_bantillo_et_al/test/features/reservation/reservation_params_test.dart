// Fix before Phase 3: the signature is checked against the full name
// submitted with the booking (Card 1), not the profile name.
//   * create_reservation receives Card 1's name as p_customer_full_name
//     (the database compares p_signed_name to it, migration 0012).
//   * The same case / extra-space rule as the app's signature field.
//   * Booking.customerFullName reads the new column.
// Run with: flutter test test/features/reservation

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/reservation/models/agreement_form.dart';
import 'package:orange150_rental/features/reservation/models/payment_plan.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/shared/models/booking.dart';

Map<String, dynamic> _params({
  required String fullName,
  required String signedName,
}) => ReservationService.reservationParams(
  itemId: 'i1',
  eventDate: DateTime(2026, 12, 24),
  paymentOption: PaymentOption.half,
  measurementsSnapshot: const {},
  termsVersion: '2026-11',
  fullName: fullName,
  signedName: signedName,
  termsAcknowledgedAt: DateTime.utc(2026, 11, 24, 2),
  termsSnapshot: const {'terms': <String>[]},
  paymentMethod: PlannedPaymentMethod.gcash,
);

void main() {
  test('sends the Card 1 name as p_customer_full_name', () {
    // The customer edited their name in Card 1 (the profile may still say
    // something else); that edited name is what goes to the database.
    final params = _params(
      fullName: '  Ana Maria Cruz ',
      signedName: 'ana maria cruz',
    );
    expect(params['p_customer_full_name'], 'Ana Maria Cruz');
    expect(params['p_signed_name'], 'ana maria cruz');
    expect(params['p_event_date'], '2026-12-24');
    expect(params['p_preferred_payment_method'], 'gcash');
  });

  test('the signature matches the submitted name, ignoring case and '
      'extra spaces', () {
    const cardName = 'Ana Maria Cruz';
    const profileName = 'Ana Cruz'; // old name still on the profile

    expect(AgreementRules.nameMatches('  ana   MARIA cruz ', cardName), isTrue);
    // Signing with the old profile name no longer counts.
    expect(AgreementRules.nameMatches(profileName, cardName), isFalse);
  });

  test('Booking reads customer_full_name (null on older bookings)', () {
    final row = {
      'id': 'b1',
      'reference_no': 'O150-1',
      'customer_id': 'c1',
      'status': 'pending',
      'payment_option': 'half',
      'total_amount': 2500,
      'amount_paid': 0,
      'pickup_date': '2026-12-23',
      'event_date': '2026-12-24',
      'return_date': '2026-12-25',
    };
    expect(Booking.fromMap(row).customerFullName, isNull);
    expect(
      Booking.fromMap({...row, 'customer_full_name': 'Ana Maria Cruz'})
          .customerFullName,
      'Ana Maria Cruz',
    );
  });
}
