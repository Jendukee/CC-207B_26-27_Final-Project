// Month calendar of an item's availability (customer redesign, Phase 1).
// Used twice:
//   * on Item details, read-only style: tapping a free date opens the
//     Reserve sheet with that date chosen
//   * inside the Reserve sheet, to pick the event date
//
// A date can be the EVENT date only if its pick-up (day before), the event
// and the return (day after) are all free (EventDateRules.isFree). Dates
// that cannot be chosen are greyed out and struck through, with a legend,
// so the meaning is not carried by color alone.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/reservation/models/event_date_rules.dart';

/// An availability month view.
class AvailabilityCalendar extends StatefulWidget {
  /// Creates the calendar.
  const AvailabilityCalendar({
    super.key,
    required this.blockedDays,
    required this.earliest,
    required this.latest,
    required this.onSelect,
    this.selected,
  });

  /// Days already held by reserved / rented-out bookings.
  final Set<DateTime> blockedDays;

  /// First event date allowed (2 days from today).
  final DateTime earliest;

  /// Last date shown.
  final DateTime latest;

  /// The chosen event date, highlighted with its 3-day window.
  final DateTime? selected;

  /// Called with a free event date when the customer taps it.
  final ValueChanged<DateTime> onSelect;

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focused = widget.selected ?? widget.earliest;

  /// table_calendar passes UTC days; compare plain local dates.
  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _canChoose(DateTime day) {
    final d = _day(day);
    return !d.isBefore(_day(widget.earliest)) &&
        !d.isAfter(widget.latest) &&
        EventDateRules.isFree(d, widget.blockedDays);
  }

  /// True for the pick-up, event and return days of the chosen date.
  bool _inWindow(DateTime day) {
    final selected = widget.selected;
    if (selected == null) return false;
    final diff = _day(day).difference(_day(selected)).inDays;
    return diff >= -1 && diff <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<void>(
          firstDay: DateTime(widget.earliest.year, widget.earliest.month),
          lastDay: widget.latest,
          focusedDay: _focused,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          rowHeight: 44,
          enabledDayPredicate: _canChoose,
          selectedDayPredicate: (day) =>
              widget.selected != null && isSameDay(day, widget.selected),
          onDaySelected: (day, focused) {
            setState(() => _focused = focused);
            widget.onSelect(_day(day));
          },
          onPageChanged: (focused) => _focused = focused,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            selectedDecoration: const BoxDecoration(
              color: AppColors.maroon,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              border: Border.all(color: AppColors.maroon),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            disabledTextStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          calendarBuilders: CalendarBuilders<void>(
            // Pick-up and return days of the chosen date get a gold tint.
            defaultBuilder: (context, day, _) {
              if (!_inWindow(day)) return null;
              return Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.goldTint,
                  shape: BoxShape.circle,
                ),
                child: Text('${day.day}'),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Legend: every state has a text label.
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _legend(
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.maroon,
                  shape: BoxShape.circle,
                ),
              ),
              'Your event date',
            ),
            _legend(
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.goldTint,
                  shape: BoxShape.circle,
                ),
              ),
              'Pick-up / return',
            ),
            _legend(
              Text(
                '12',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              'Not available',
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(Widget swatch, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [swatch, const SizedBox(width: 6), Text(label)],
  );
}
