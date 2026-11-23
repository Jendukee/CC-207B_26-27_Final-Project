// Payment rules for the Record Payment form, in plain Dart (no Flutter, no
// Supabase) so they can be unit tested.
//
// These are the SAME rules the record_payment SQL function enforces
// (supabase/migrations/0002_shop_bookings.sql). The form checks them first
// so staff see the problem inline; the database checks them again so the
// rules hold even if the app has a bug.
//
// All money math is done in centavos (int) to avoid floating point errors
// such as 0.1 + 0.2 != 0.3.
//
// OWNER: Member 3.

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/payment.dart';

/// How the customer paid. Stored in payments.method.
enum PaymentMethod {
  /// Cash at the shop.
  cash('cash', 'Cash'),

  /// GCash e-wallet.
  gcash('gcash', 'GCash'),

  /// Bank transfer or deposit.
  bank('bank', 'Bank transfer');

  const PaymentMethod(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to staff.
  final String label;

  /// Label for a stored value, e.g. "gcash" -> "GCash". Unknown values are
  /// shown as they are.
  static String labelFor(String dbValue) {
    for (final method in values) {
      if (method.dbValue == dbValue) return method.label;
    }
    return dbValue;
  }
}

/// Pure functions for payment amounts.
abstract final class PaymentRules {
  /// Pesos -> centavos, e.g. 1500.5 -> 150050.
  static int toCents(double pesos) => (pesos * 100).round();

  /// Centavos -> pesos, e.g. 150050 -> 1500.5.
  static double fromCents(int cents) => cents / 100;

  /// Remaining balance in pesos (never negative).
  static double balance({required double total, required double paid}) {
    final cents = toCents(total) - toCents(paid);
    return fromCents(cents < 0 ? 0 : cents);
  }

  /// 50% of [total], rounded to the centavo (same as SQL round(total*0.5, 2)).
  static double downPaymentFor(double total) =>
      fromCents((toCents(total) / 2).round());

  /// Payment kinds staff may pick. Before any payment: full or down.
  /// After a payment exists: balance only.
  static List<PaymentKind> allowedKinds({required double paid}) => paid > 0
      ? const [PaymentKind.balance]
      : const [PaymentKind.full, PaymentKind.down];

  /// The amount the form pre-fills for [kind].
  static double suggestedAmount(
    PaymentKind kind, {
    required double total,
    required double paid,
  }) {
    return switch (kind) {
      PaymentKind.full => total,
      PaymentKind.down => downPaymentFor(total),
      PaymentKind.balance => balance(total: total, paid: paid),
    };
  }

  /// Parses the amount field. Commas and a leading peso sign are allowed
  /// ("₱1,500.00"). Returns null if it is not a number.
  static double? parseAmount(String? text) {
    final cleaned = (text ?? '').replaceAll(RegExp(r'[₱,\s]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Validates the amount field. Returns null when valid, otherwise a
  /// message for the form field.
  static String? validateAmount(
    String? text, {
    required PaymentKind kind,
    required double total,
    required double paid,
  }) {
    final raw = (text ?? '').trim();
    if (raw.isEmpty) return 'Enter the amount paid.';

    final amount = parseAmount(raw);
    if (amount == null) return 'Enter a number, for example 1500.';
    if (amount <= 0) return 'Enter an amount greater than 0.';

    // More than 2 decimal places? (e.g. 100.555)
    if ((amount * 100 - toCents(amount)).abs() > 0.000001) {
      return 'Use at most 2 decimal places.';
    }

    final amountCents = toCents(amount);
    final balanceCents = toCents(balance(total: total, paid: paid));
    if (amountCents > balanceCents) {
      return 'Amount cannot be more than the balance of '
          '${Formatters.peso(fromCents(balanceCents))}.';
    }

    switch (kind) {
      case PaymentKind.full:
        if (paid > 0) {
          return 'This booking already has a payment. Choose Balance.';
        }
        if (amountCents != toCents(total)) {
          return 'A full payment must equal the total of '
              '${Formatters.peso(total)}.';
        }
      case PaymentKind.down:
        if (paid > 0) {
          return 'This booking already has a payment. Choose Balance.';
        }
        final half = downPaymentFor(total);
        if (amountCents != toCents(half)) {
          return 'A down payment must be exactly 50% of the total '
              '(${Formatters.peso(half)}).';
        }
      case PaymentKind.balance:
        if (paid <= 0) return 'Record a full or down payment first.';
    }
    return null;
  }
}
