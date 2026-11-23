// Markers under a calendar day: one dot per booking in its status color
// (same colors as StatusChip), at most 3 dots then "+N", and a red warning
// icon when the day has a conflict.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_legend.dart';

/// The marker row for one day.
class DayMarker extends StatelessWidget {
  /// Creates the markers.
  const DayMarker({
    super.key,
    required this.bookings,
    required this.hasConflict,
  });

  /// Bookings on this day.
  final List<CalendarBooking> bookings;

  /// True when two blocking bookings hold the same item on this day.
  final bool hasConflict;

  /// Most dots before "+N".
  static const int maxDots = 3;

  @override
  Widget build(BuildContext context) {
    final extra = bookings.length - maxDots;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasConflict)
            const Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: calendarConflictColor,
            ),
          for (final booking in bookings.take(maxDots))
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StatusChip.colorFor(
                  CalendarRules.displayStatus(booking),
                ),
              ),
            ),
          if (extra > 0) Text('+$extra', style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
