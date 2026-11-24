// Unit tests for the shared money and measurement input formatters in
// lib/core/utils/validators.dart (UI audit #16 and #24).
// Run with: flutter test test/core

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/utils/validators.dart';

/// Types [next] into a field that currently shows [current], through
/// [formatters], and returns what the field shows afterwards.
String type(List<TextInputFormatter> formatters, String current, String next) {
  final oldValue = TextEditingValue(text: current);
  var value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
  for (final formatter in formatters) {
    value = formatter.formatEditUpdate(oldValue, value);
  }
  return value.text;
}

void main() {
  final money = Validators.moneyFormatters;
  final inches = Validators.measurementFormatters;

  group('moneyFormatters', () {
    test('accept whole numbers and up to 2 decimals', () {
      expect(type(money, '', '1500'), '1500');
      expect(type(money, '1500', '1500.'), '1500.');
      expect(type(money, '1500.5', '1500.50'), '1500.50');
      expect(type(money, '', '.5'), '.5');
    });

    test('reject letters, commas, a second dot and a 3rd decimal', () {
      expect(type(money, '150', '150a'), '150');
      expect(type(money, '1', '1,'), '1');
      expect(type(money, '1.5', '1.5.'), '1.5');
      expect(type(money, '1500.50', '1500.505'), '1500.50');
      expect(type(money, '', '-5'), '');
    });
  });

  group('measurementFormatters', () {
    test('accept inches like 32.5', () {
      expect(type(inches, '32', '32.5'), '32.5');
    });

    test('reject more than 3 whole digits', () {
      expect(type(inches, '120', '1205'), '120');
    });
  });
}
