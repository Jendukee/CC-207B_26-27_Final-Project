// Shared form validators. Each returns null when valid or an error message
// when invalid, so they plug straight into TextFormField.validator.
//
// Example:
//   validator: Validators.combine([
//     (v) => Validators.required(v, fieldName: 'Waist'),
//     (v) => Validators.numberRange(v, min: 15, max: 70, fieldName: 'Waist'),
//   ]),
//
// Phone numbers (UI audit, finding #1): every mobile field in the app uses
// the SAME rules from this file, usually through core/widgets/
// phone_form_field.dart:
//   * Validators.phone            exactly 11 digits starting with 09
//   * Validators.phoneFormatters  digits only, at most 11
//   * Validators.normalizePhone   cleans old values ("+63 917 ..." -> "0917...")
// The database checks the same pattern (0008_profiles_phone_check.sql).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/services.dart';

/// Reusable validation functions.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Philippine mobile: exactly 11 digits starting with 09 (09XXXXXXXXX).
  static final RegExp _phPhonePattern = RegExp(r'^09\d{9}$');

  /// Error shown for an invalid mobile number.
  static const String phoneFormatError =
      'Enter an 11-digit mobile number starting with 09, '
      'for example 09171234567.';

  /// Helper text shown under every mobile number field.
  static const String phoneHelperText = 'Format: 09XXXXXXXXX';

  /// Input formatters for every mobile number field: letters, spaces and
  /// symbols cannot be typed or pasted, and at most 11 digits fit.
  static final List<TextInputFormatter> phoneFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(11),
  ];

  /// Fails when the value is null or only whitespace.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    return null;
  }

  /// Required + basic email format.
  static String? email(String? value) {
    final missing = required(value, fieldName: 'Email');
    if (missing != null) return missing;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Philippine mobile number: exactly 11 digits starting with 09.
  /// Spaces, dashes and "+63" are NOT accepted (the field's formatters
  /// already stop them from being typed). When [isRequired] is false, an
  /// empty value is accepted.
  static String? phone(String? value, {bool isRequired = true}) {
    final text = value ?? '';
    if (text.trim().isEmpty) {
      return isRequired ? 'Mobile number is required.' : null;
    }
    if (!_phPhonePattern.hasMatch(text)) return phoneFormatError;
    return null;
  }

  /// Turns an older saved number into 09XXXXXXXXX, or null if it cannot
  /// be fixed. Used to pre-fill edit forms. Examples:
  ///   "0917 123 4567" -> "09171234567"
  ///   "+63 917 123 4567" / "639171234567" -> "09171234567"
  ///   "9171234567" -> "09171234567"
  static String? normalizePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    String? result;
    if (digits.length == 11 && digits.startsWith('09')) {
      result = digits;
    } else if (digits.length == 12 && digits.startsWith('639')) {
      result = '0${digits.substring(2)}';
    } else if (digits.length == 10 && digits.startsWith('9')) {
      result = '0$digits';
    }
    return result;
  }

  /// A number between [min] and [max] inclusive (e.g. measurements in
  /// inches, prices in pesos).
  static String? numberRange(
    String? value, {
    required num min,
    required num max,
    String fieldName = 'Value',
    bool isRequired = true,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return isRequired ? '$fieldName is required.' : null;
    final number = num.tryParse(text);
    if (number == null) return '$fieldName must be a number.';
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max.';
    }
    return null;
  }

  /// Password with a minimum length.
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  /// Runs [validators] in order and returns the first error.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validate in validators) {
        final error = validate(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
