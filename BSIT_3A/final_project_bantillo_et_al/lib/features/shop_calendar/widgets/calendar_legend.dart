// Color legend for the staff calendar: one StatusChip per status shown,
// plus the red "Conflict" marker. Every color has a text label, so the
// calendar never relies on color alone.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';

/// Red used for conflicts. Brighter than the Rented Out red so the two
/// can be told apart; the "Conflict" label is always shown with it.
const Color calendarConflictColor = Color(0xFFD32F2F);

/// The legend row.
class CalendarLegend extends StatelessWidget {
  /// Creates the legend.
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final status in CalendarRules.shownStatuses)
          StatusChip.booking(status),
        const StatusChip(
          label: 'Conflict',
          color: calendarConflictColor,
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}
