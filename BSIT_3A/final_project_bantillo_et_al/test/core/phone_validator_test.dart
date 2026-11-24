// Unit tests for the shared mobile number rules in
// lib/core/utils/validators.dart (UI audit, finding #1):
// Validators.phone, Validators.phoneFormatters and Validators.normalizePhone.
// Run with: flutter test test/core

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/utils/validators.dart';

/// Runs [text] through the phone formatters as if it were typed or pasted
/// into an empty field, and returns what the field would contain.
String typed(String text) {
  var value = const TextEditingValue();
  final next = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  var result = next;
  for (final formatter in Validators.phoneFormatters) {
    result = formatter.formatEditUpdate(value, result);
  }
  value = result;
  return value.text;
}

void main() {
  group('Validators.phone', () {
    test('accepts 11 digits starting with 09', () {
      expect(Validators.phone('09171234567'), isNull);
    });

    test('rejects letters', () {
      expect(Validators.phone('0917abc4567'), Validators.phoneFormatError);
    });

    test('rejects 10 and 12 digits', () {
      expect(Validators.phone('0917123456'), Validators.phoneFormatError);
      expect(Validators.phone('091712345678'), Validators.phoneFormatError);
    });

    test('rejects numbers that do not start with 09', () {
      expect(Validators.phone('08171234567'), Validators.phoneFormatError);
      expect(Validators.phone('+639171234567'), Validators.phoneFormatError);
    });

    test('rejects spaces', () {
      expect(Validators.phone('0917 123 4567'), Validators.phoneFormatError);
    });

    test('empty: error when required, OK when optional', () {
      expect(Validators.phone(''), 'Mobile number is required.');
      expect(Validators.phone('', isRequired: false), isNull);
      expect(Validators.phone(null, isRequired: false), isNull);
    });

    test('error message tells the user the exact format', () {
      expect(
        Validators.phoneFormatError,
        'Enter an 11-digit mobile number starting with 09, '
        'for example 09171234567.',
      );
    });
  });

  group('Validators.phoneFormatters', () {
    test('keep only digits (letters, spaces and symbols are removed)', () {
      expect(typed('0917 abc-123'), '0917123');
      expect(typed('+63 917'), '63917');
    });

    test('stop at 11 digits, also when pasting a longer value', () {
      expect(typed('09171234567'), '09171234567');
      expect(typed('091712345678999'), '09171234567');
    });
  });

  group('Validators.normalizePhone', () {
    test('fixes older saved formats', () {
      expect(Validators.normalizePhone('0917 123 4567'), '09171234567');
      expect(Validators.normalizePhone('+63 917 123 4567'), '09171234567');
      expect(Validators.normalizePhone('639171234567'), '09171234567');
      expect(Validators.normalizePhone('9171234567'), '09171234567');
    });

    test('returns null when it cannot be fixed', () {
      expect(Validators.normalizePhone('12345'), isNull);
      expect(Validators.normalizePhone('08171234567'), isNull);
      expect(Validators.normalizePhone(''), isNull);
      expect(Validators.normalizePhone(null), isNull);
    });
  });
}
