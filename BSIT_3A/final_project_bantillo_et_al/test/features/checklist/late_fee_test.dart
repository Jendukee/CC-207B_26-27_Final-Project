// Phase 3: the return checklist pre-fills a late fee of ₱200 per day after
// the return date, and explains how it was worked out.
// Run with: flutter test test/features/checklist

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/features/checklist/models/checklist_rules.dart';

void main() {
  final due = DateTime(2026, 11, 25); // booking return date

  group('lateDays / lateFee', () {
    test('on time or early: no fee (the time of day is ignored)', () {
      for (final back in [
        DateTime(2026, 11, 24, 18),
        DateTime(2026, 11, 25),
        DateTime(2026, 11, 25, 23, 59),
      ]) {
        expect(ChecklistRules.lateDays(returnDate: due, returnedOn: back), 0);
        expect(ChecklistRules.lateFee(returnDate: due, returnedOn: back), 0);
      }
    });

    test('₱200 for each extra day', () {
      expect(
        ChecklistRules.lateFee(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 26, 0, 5),
        ),
        200,
      );
      expect(
        ChecklistRules.lateFee(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 28, 9),
        ),
        600,
      );
    });

    test('counts across a month end', () {
      expect(
        ChecklistRules.lateDays(
          returnDate: DateTime(2026, 11, 30),
          returnedOn: DateTime(2026, 12, 2),
        ),
        2,
      );
    });
  });

  group('lateFeeExplanation', () {
    test('shows days, rate and total', () {
      final text = ChecklistRules.lateFeeExplanation(
        returnDate: due,
        returnedOn: DateTime(2026, 11, 27),
      );
      expect(text, contains('2 days late'));
      expect(text, contains('₱200.00'));
      expect(text, contains('₱400.00'));
    });

    test('one day uses "day"', () {
      expect(
        ChecklistRules.lateFeeExplanation(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 26),
        ),
        startsWith('1 day late'),
      );
    });

    test('on time says no late fee', () {
      expect(
        ChecklistRules.lateFeeExplanation(returnDate: due, returnedOn: due),
        contains('no late fee'),
      );
    });
  });

  test('penaltyText has no trailing ".0" and passes validation', () {
    expect(ChecklistRules.penaltyText(400), '400');
    expect(ChecklistRules.penaltyText(0), '0');
    expect(ChecklistRules.penaltyText(12.5), '12.50');
    expect(
      ChecklistRules.validatePenalty(ChecklistRules.penaltyText(400)),
      isNull,
    );
  });
}
