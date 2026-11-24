// How much the customer pays now and later, for the checkout's payment
// card and bottom bar (customer redesign, Phase 1). Plain Dart so it can be
// unit tested. Money is computed in centavos to avoid rounding errors.
//
//   50% reservation fee : pay now = half the total (rounded to the
//                         centavo, same as the database), balance at pick-up
//   Full payment        : pay now = the total, balance 0
//
// Moved from features/reservation/models to shared/models so checkout,
// Request submitted and my_bookings use it without importing another
// feature's files.
//
// OWNER: team lead (shared). Change only via a reviewed PR.

import 'package:orange150_rental/shared/models/booking.dart';

/// Payment method the customer plans to use (chosen at checkout).
enum PlannedPaymentMethod {
  /// Pay in cash at the shop.
  cash('cash', 'Cash'),

  /// Send to the shop's GCash number.
  gcash('gcash', 'GCash'),

  /// Bank transfer (the shop sends the account details).
  bank('bank', 'Bank transfer');

  const PlannedPaymentMethod(this.dbValue, this.label);

  /// Value used in links and (later) the database.
  final String dbValue;

  /// Text shown to customers.
  final String label;

  /// The method for [value]; unknown values give null.
  static PlannedPaymentMethod? fromDb(String? value) {
    for (final method in values) {
      if (method.dbValue == value) return method;
    }
    return null;
  }
}

/// Amounts for one payment option.
abstract final class PaymentPlan {
  /// Amount to pay now for [option] on a [total] rental.
  static double dueNow(double total, PaymentOption option) {
    final cents = (total * 100).round();
    final due = option == PaymentOption.half ? (cents / 2).round() : cents;
    return due / 100;
  }

  /// What is left to pay at pick-up.
  static double balanceAfter(double total, PaymentOption option) {
    final cents = (total * 100).round();
    return (cents - (dueNow(total, option) * 100).round()) / 100;
  }
}
