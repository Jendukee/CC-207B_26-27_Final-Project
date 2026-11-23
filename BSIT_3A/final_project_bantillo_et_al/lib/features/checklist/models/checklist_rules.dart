// Checklist rules in plain Dart (no Flutter, no Supabase) so they can be
// unit tested:
//   * which checkboxes to show (the garment itself + each inclusion)
//   * when "Release items" is allowed
//   * penalty validation (0 or more)
// The save_checklist SQL function (0003) checks the same rules again.
//
// OWNER: Member 3.

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
}
