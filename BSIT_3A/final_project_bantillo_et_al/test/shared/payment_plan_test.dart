// Unit tests for PaymentPlan (customer redesign, Phase 1): the "Pay now"
// and balance amounts on the checkout.
// Run with: flutter test test/shared

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

void main() {
  test('50% reservation fee pays half now and half at pick-up', () {
    expect(PaymentPlan.dueNow(3500, PaymentOption.half), 1750);
    expect(PaymentPlan.balanceAfter(3500, PaymentOption.half), 1750);
  });

  test('full payment pays everything now', () {
    expect(PaymentPlan.dueNow(3500, PaymentOption.full), 3500);
    expect(PaymentPlan.balanceAfter(3500, PaymentOption.full), 0);
  });

  test('odd centavos round like the database, and add up to the total', () {
    // 999.99 / 2 = 499.995 -> 500.00 now, 499.99 later.
    expect(PaymentPlan.dueNow(999.99, PaymentOption.half), 500);
    expect(PaymentPlan.balanceAfter(999.99, PaymentOption.half), 499.99);
  });

  test('payment methods parse from link values', () {
    expect(PlannedPaymentMethod.fromDb('gcash'), PlannedPaymentMethod.gcash);
    expect(PlannedPaymentMethod.fromDb('x'), isNull);
  });
}
