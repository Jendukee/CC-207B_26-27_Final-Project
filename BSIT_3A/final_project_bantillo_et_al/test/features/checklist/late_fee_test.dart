// Phase 3: the return checklist pre-fills a late fee of ₱200 per day after
// the return date, and explains how it was worked out.
// Shop settings (0016): the rate is the owner's late fee per day, loaded by
// ShopSettingsService; if loading fails the old ₱200 is used.
// Run with: flutter test test/features/checklist

import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/services/shop_settings_service.dart';
import 'package:orange150_rental/features/checklist/models/checklist_rules.dart';

/// A shop_settings row with [fee], or a failing read when [fee] is null.
class _FakeSettingsApi implements ShopSettingsApi {
  _FakeSettingsApi(this.fee);

  final num? fee;
  int reads = 0;

  @override
  Future<Map<String, dynamic>?> readRow() async {
    reads++;
    if (fee == null) throw Exception('offline');
    return {'id': 1, 'late_fee_per_day': fee, 'payment_window_hours': 48};
  }

  @override
  Future<Map<String, dynamic>> update(Map<String, dynamic> params) =>
      throw UnimplementedError();
}

void main() {
  final due = DateTime(2026, 11, 25); // booking return date

  group('late fee from the loaded shop settings', () {
    test('uses the owner\'s fee per day', () async {
      final service = ShopSettingsService(api: _FakeSettingsApi(250));
      final settings = await service.load();
      expect(settings.lateFeePerDay, 250);
      expect(
        ChecklistRules.lateFee(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 27),
          perDay: settings.lateFeePerDay,
        ),
        500,
      );
      expect(
        ChecklistRules.lateFeeExplanation(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 27),
          perDay: settings.lateFeePerDay,
        ),
        contains('× ₱250.00 = ₱500.00'),
      );
    });

    test('a fee of 0 means no late fee', () async {
      final service = ShopSettingsService(api: _FakeSettingsApi(0));
      final settings = await service.load();
      expect(
        ChecklistRules.lateFee(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 28),
          perDay: settings.lateFeePerDay,
        ),
        0,
      );
    });

    test('falls back to ₱200 when the settings cannot load', () async {
      final service = ShopSettingsService(api: _FakeSettingsApi(null));
      final settings = await service.load(); // never throws
      expect(settings.lateFeePerDay, 200);
      expect(service.isLoaded, isFalse);
      expect(
        ChecklistRules.lateFee(
          returnDate: due,
          returnedOn: DateTime(2026, 11, 26),
          perDay: settings.lateFeePerDay,
        ),
        200,
      );
    });

    test('loaded once, then cached', () async {
      final api = _FakeSettingsApi(300);
      final service = ShopSettingsService(api: api);
      await service.load();
      await service.load();
      expect(api.reads, 1);
      expect(service.current.lateFeePerDay, 300);
    });
  });

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
