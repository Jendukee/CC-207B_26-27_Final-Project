// Unit tests for the checklist feature that need no Supabase connection:
// checkbox lines, the release rule, penalty validation and error messages.
// Run with: flutter test test/features/checklist

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/features/checklist/models/checklist_booking.dart';
import 'package:orange150_rental/features/checklist/models/checklist_rules.dart';
import 'package:orange150_rental/features/checklist/services/checklist_service.dart';

void main() {
  const gown = ChecklistItem(
    itemId: 'i1',
    name: 'Ivory Ball Gown',
    size: 'M',
    inclusions: ['Petticoat', 'Gloves'],
  );
  const barong = ChecklistItem(itemId: 'i2', name: 'Kids Barong', size: '10');

  group('buildLines', () {
    test('one line for the garment plus one per inclusion', () {
      final lines = ChecklistRules.buildLines([gown, barong]);
      expect(lines.map((l) => l.key), [
        'Ivory Ball Gown: Garment',
        'Ivory Ball Gown: Petticoat',
        'Ivory Ball Gown: Gloves',
        'Kids Barong: Garment',
      ]);
    });

    test('keys stay unique when two items share a name', () {
      final lines = ChecklistRules.buildLines([barong, barong]);
      expect(lines.map((l) => l.key), [
        'Kids Barong: Garment',
        'Kids Barong #2: Garment',
      ]);
    });
  });

  group('release rule', () {
    final lines = ChecklistRules.buildLines([gown]);
    final allKeys = lines.map((l) => l.key).toSet();

    test('needs every inclusion ticked and no balance', () {
      expect(
        ChecklistRules.canRelease(lines: lines, ticked: allKeys, balance: 0),
        isTrue,
      );
      expect(
        ChecklistRules.canRelease(
          lines: lines,
          ticked: {'Ivory Ball Gown: Garment'},
          balance: 0,
        ),
        isFalse,
      );
      expect(
        ChecklistRules.canRelease(lines: lines, ticked: allKeys, balance: 100),
        isFalse,
      );
    });

    test('explains why release is blocked', () {
      expect(
        ChecklistRules.releaseBlockedReason(
          lines: lines,
          ticked: {},
          balance: 0,
        ),
        'Tick every inclusion first (3 left).',
      );
      expect(
        ChecklistRules.releaseBlockedReason(
          lines: lines,
          ticked: allKeys,
          balance: 50,
        ),
        contains('balance'),
      );
      expect(
        ChecklistRules.releaseBlockedReason(
          lines: lines,
          ticked: allKeys,
          balance: 0,
        ),
        isNull,
      );
    });

    test('an empty checklist cannot be released', () {
      expect(ChecklistRules.allTicked(const [], {}), isFalse);
    });

    test('checkedMap marks missing items false', () {
      final map = ChecklistRules.checkedMap(lines, {'Ivory Ball Gown: Gloves'});
      expect(map, {
        'Ivory Ball Gown: Garment': false,
        'Ivory Ball Gown: Petticoat': false,
        'Ivory Ball Gown: Gloves': true,
      });
    });
  });

  group('validatePenalty', () {
    test('accepts 0 and positive amounts', () {
      expect(ChecklistRules.validatePenalty('0'), isNull);
      expect(ChecklistRules.validatePenalty('250.50'), isNull);
    });

    test('rejects negatives, text, blanks and extra decimals', () {
      expect(
        ChecklistRules.validatePenalty('-1'),
        'Enter a penalty of 0 or more.',
      );
      expect(ChecklistRules.validatePenalty('abc'), contains('number'));
      expect(ChecklistRules.validatePenalty(''), contains('required'));
      expect(
        ChecklistRules.validatePenalty('10.555'),
        'Use at most 2 decimal places.',
      );
    });
  });

  group('ChecklistService.friendlyError', () {
    test('shows our SQL messages, also when wrapped in raw JSON', () {
      const wrapped = PostgrestException(
        message:
            '{"code":"P0001","message":"Tick every inclusion before '
            'releasing the items."}',
        code: '400',
      );
      expect(
        ChecklistService.friendlyError(wrapped),
        'Tick every inclusion before releasing the items.',
      );
    });

    test('upload failures ask the user to retry', () {
      const failed = StorageException('timeout', statusCode: '500');
      expect(ChecklistService.friendlyError(failed), contains('Retry'));
    });
  });
}
