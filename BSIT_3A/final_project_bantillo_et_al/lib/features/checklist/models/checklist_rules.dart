// Checklist rules in plain Dart (no Flutter, no Supabase) so they can be
// unit tested:
//   * which checkboxes to show (the garment itself + each inclusion)
//   * when "Release items" is allowed
//   * penalty validation (0 or more)
//   * the late return fee (Phase 3): the shop's fee per day after the
//     return date. Shop settings (0016): the rate is passed in as
//     `perDay` (the owner's value from ShopSettingsService); left out, it
//     is the old fixed ₱200 (RentalTerms.lateFeePerDay).
// The save_checklist SQL function (0003) checks the same rules again.
//
// OWNER: Member 3.

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/features/checklist/models/checklist_booking.dart';

/// One checkbox on the checklist.
class InclusionLine {
  /// Creates a line.
  const InclusionLine({
    required this.key,
    required this.itemName,
    required this.label,
  });

  /// Unique key stored in checklists.inclusions_checked,
  /// e.g. "Ivory Ball Gown: Gloves".
  final String key;

  /// The item this line belongs to (used as a group heading).
  final String itemName;

  /// Checkbox text, e.g. "Gloves" or "Garment".
  final String label;
}

/// Pure checklist functions.
abstract final class ChecklistRules {
  /// Label of the line for the garment itself.
  static const String garmentLabel = 'Garment';

  /// Highest penalty the form accepts, in pesos.
  static const double maxPenalty = 100000;

  /// One line for each garment plus one for each of its inclusions.
  /// Keys are made unique if two items share a name.
  static List<InclusionLine> buildLines(List<ChecklistItem> items) {
    final lines = <InclusionLine>[];
    final usedNames = <String, int>{};
    for (final item in items) {
      // "Gown", then "Gown #2" if the same name appears again.
      final count = (usedNames[item.name] ?? 0) + 1;
      usedNames[item.name] = count;
      final itemName = count == 1 ? item.name : '${item.name} #$count';

      for (final label in [garmentLabel, ...item.inclusions]) {
        lines.add(
          InclusionLine(
            key: '$itemName: $label',
            itemName: itemName,
            label: label,
          ),
        );
      }
    }
    return lines;
  }

  /// The checked state of every line, false when not ticked yet.
  static Map<String, bool> checkedMap(
    List<InclusionLine> lines,
    Set<String> ticked,
  ) => {for (final line in lines) line.key: ticked.contains(line.key)};

  /// True when every line is ticked (and there is at least one).
  static bool allTicked(List<InclusionLine> lines, Set<String> ticked) =>
      lines.isNotEmpty && lines.every((line) => ticked.contains(line.key));

  /// "Release items" needs every inclusion ticked and nothing owed.
  static bool canRelease({
    required List<InclusionLine> lines,
    required Set<String> ticked,
    required double balance,
  }) => allTicked(lines, ticked) && balance <= 0;

  /// Why "Release items" is disabled, or null when it is enabled.
  static String? releaseBlockedReason({
    required List<InclusionLine> lines,
    required Set<String> ticked,
    required double balance,
  }) {
    if (balance > 0) return 'Collect the balance before releasing the items.';
    if (!allTicked(lines, ticked)) {
      final left = lines.where((l) => !ticked.contains(l.key)).length;
      return 'Tick every inclusion first ($left left).';
    }
    return null;
  }

  /// Penalty field validator: a number from 0 up to [maxPenalty] with at
  /// most 2 decimals. Uses the shared Validators for the range check.
  static String? validatePenalty(String? value) {
    final rangeError = Validators.numberRange(
      value,
      min: 0,
      max: maxPenalty,
      fieldName: 'Penalty',
    );
    if (rangeError != null) {
      // Clearer wording for the common mistake of a negative number.
      final number = num.tryParse((value ?? '').trim());
      if (number != null && number < 0) return 'Enter a penalty of 0 or more.';
      return rangeError;
    }
    final number = num.parse(value!.trim());
    if (((number * 100) - (number * 100).round()).abs() > 0.000001) {
      return 'Use at most 2 decimal places.';
    }
    return null;
  }

  /// The penalty as a number (0 when the field is empty or invalid).
  static double parsePenalty(String? value) =>
      double.tryParse((value ?? '').trim()) ?? 0;

  // ---------------------------------------------------------------------------
  // Late return fee (Phase 3, rental term 5: ₱200 per extra day)
  // ---------------------------------------------------------------------------

  /// Whole calendar days between [returnDate] and the day of [returnedOn]
  /// (0 when returned on or before the return date). Times are ignored,
  /// so returning at 11 pm on the return date is still on time.
  static int lateDays({
    required DateTime returnDate,
    required DateTime returnedOn,
  }) {
    // UTC dates: whole days, no daylight-saving surprises.
    final due = DateTime.utc(returnDate.year, returnDate.month, returnDate.day);
    final back = DateTime.utc(
      returnedOn.year,
      returnedOn.month,
      returnedOn.day,
    );
    final days = back.difference(due).inDays;
    return days < 0 ? 0 : days;
  }

  /// The late fee to pre-fill: [lateDays] x [perDay] (the shop's late fee
  /// per day; default RentalTerms.lateFeePerDay).
  static double lateFee({
    required DateTime returnDate,
    required DateTime returnedOn,
    double perDay = RentalTerms.lateFeePerDay,
  }) => lateDays(returnDate: returnDate, returnedOn: returnedOn) * perDay;

  /// How the pre-filled fee was worked out, shown under the penalty field:
  /// "2 days late (due Nov 25, 2026) × ₱200.00 = ₱400.00." or
  /// "Returned on time (due Nov 25, 2026): no late fee."
  static String lateFeeExplanation({
    required DateTime returnDate,
    required DateTime returnedOn,
    double perDay = RentalTerms.lateFeePerDay,
  }) {
    final days = lateDays(returnDate: returnDate, returnedOn: returnedOn);
    final due = Formatters.date(returnDate);
    if (days == 0) return 'Returned on time (due $due): no late fee.';
    return '$days ${days == 1 ? 'day' : 'days'} late (due $due) × '
        '${Formatters.peso(perDay)} = '
        '${Formatters.peso(days * perDay)}.';
  }

  /// The penalty field text for a fee: "400" or "0" (no trailing ".0").
  static String penaltyText(double amount) => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}
