// The rules of the Shop settings form (More -> Shop settings), in plain
// Dart so they can be unit tested. update_shop_settings (0016) checks the
// same rules again in the database:
//
//   address           required, at most 200 characters
//   contact numbers   1 to 3, each 09XXXXXXXXX (shared Validators.phone),
//                     no number twice
//   GCash number      required, 09XXXXXXXXX
//   shop hours        optional, at most 120 characters
//   payment window    one of [paymentWindowChoices] (1 to 168 hours)
//   late fee per day  0 or more, at most 2 decimals, below ₱1,000,000
//
// OWNER: Member 3.

import 'package:flutter/services.dart' show TextInputFormatter;

import 'package:orange150_rental/core/config/shop_settings.dart';
import 'package:orange150_rental/core/utils/validators.dart';

/// Validation and helpers for the Shop settings form.
abstract final class ShopSettingsForm {
  /// Payment window choices in the dropdown, in hours.
  static const List<int> paymentWindowChoices = [12, 24, 48, 72];

  /// Most contact numbers the shop can list.
  static const int maxContactNumbers = 3;

  /// Longest address and shop hours text.
  static const int maxAddressLength = 200;

  /// Longest shop hours text.
  static const int maxHoursLength = 120;

  /// Highest late fee accepted (the column is numeric(10,2)).
  static const double maxLateFee = 999999.99;

  /// Helper text under the shop hours field.
  static const String hoursHelper = 'Example: Mon to Sat, 9:00 AM to 6:00 PM';

  /// Late fee input: up to 6 digits and 2 decimals (shared formatter).
  static final List<TextInputFormatter> lateFeeFormatters = [
    Validators.decimalFormatter(maxWholeDigits: 6),
  ];

  /// The dropdown items: the standard choices, plus the saved value if the
  /// database holds another one (so it is never lost silently).
  static List<int> windowChoicesFor(int current) =>
      {...paymentWindowChoices, current}.toList()..sort();

  /// "48 hours (2 days)", "12 hours".
  static String windowLabel(int hours) => hours % 24 == 0
      ? '$hours hours (${hours ~/ 24} ${hours == 24 ? 'day' : 'days'})'
      : '$hours hours';

  /// Address: required, short.
  static String? validateAddress(String? value) {
    final missing = Validators.required(value, fieldName: 'Shop address');
    if (missing != null) return missing;
    if (value!.trim().length > maxAddressLength) {
      return 'Keep the address to $maxAddressLength characters or less.';
    }
    return null;
  }

  /// Shop hours: optional, short.
  static String? validateHours(String? value) {
    if ((value ?? '').trim().length > maxHoursLength) {
      return 'Keep the shop hours to $maxHoursLength characters or less.';
    }
    return null;
  }

  /// One contact number: required, 09XXXXXXXXX, and not a repeat of an
  /// earlier number in [all] (the field at [index]).
  static String? validateContactNumber(
    String? value, {
    required List<String> all,
    required int index,
  }) {
    final error = Validators.phone(value, isRequired: true);
    if (error != null) return error;
    final number = value!.trim();
    for (var i = 0; i < index && i < all.length; i++) {
      if (all[i].trim() == number) return 'This number is already listed.';
    }
    return null;
  }

  /// The whole list: 1 to [maxContactNumbers] numbers.
  static String? validateContactCount(int count) {
    if (count < 1) return 'Add at least one contact number.';
    if (count > maxContactNumbers) {
      return 'List at most $maxContactNumbers contact numbers.';
    }
    return null;
  }

  /// GCash number: required, 09XXXXXXXXX.
  static String? validateGcash(String? value) =>
      Validators.phone(value, isRequired: true);

  /// Payment window: 1 to 168 hours.
  static String? validateWindow(int? hours) {
    if (hours == null) return 'Choose how long customers have to pay.';
    if (hours < 1 || hours > 168) {
      return 'Choose between 1 and 168 hours.';
    }
    return null;
  }

  /// Late fee per day: a number, 0 or more, at most [maxLateFee].
  static String? validateLateFee(String? value) {
    final missing = Validators.required(value, fieldName: 'Late fee');
    if (missing != null) return missing;
    final amount = double.tryParse(value!.trim());
    if (amount == null) return 'Enter an amount, e.g. 200.';
    if (amount < 0) return 'The late fee must be 0 or more.';
    if (amount > maxLateFee) return 'The late fee is too large.';
    return null;
  }

  /// The late fee as a number (0 when invalid; validate first).
  static double parseLateFee(String value) =>
      double.tryParse(value.trim()) ?? 0;

  /// The late fee as field text: "200" or "212.50".
  static String lateFeeText(double amount) => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);

  /// True when the typed values differ from [saved] (for the discard
  /// prompt and the Save button).
  static bool hasChanges({
    required ShopSettings saved,
    required String address,
    required List<String> contactNumbers,
    required String gcash,
    required String hours,
    required int window,
    required String lateFee,
  }) {
    final numbers = contactNumbers.map((n) => n.trim()).toList();
    final sameNumbers =
        numbers.length == saved.contactNumbers.length &&
        Iterable<int>.generate(numbers.length)
            .every((i) => numbers[i] == saved.contactNumbers[i]);
    return address.trim() != saved.address ||
        !sameNumbers ||
        gcash.trim() != saved.gcashNumber ||
        hours.trim() != (saved.shopHours ?? '') ||
        window != saved.paymentWindowHours ||
        (double.tryParse(lateFee.trim()) ?? -1) != saved.lateFeePerDay;
  }
}
