// One booking in the selected day's list: reference, customer, what the
// day is for it (pick-up / event / return), items, a StatusChip and a red
// "Conflict" chip when it clashes with another booking.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_legend.dart';

/// A tappable booking row.
class DayBookingTile extends StatelessWidget {
  /// Creates the tile.
  const DayBookingTile({
    super.key,
    required this.booking,
    required this.day,
    required this.inConflict,
    required this.onTap,
  });

  /// The booking.
  final CalendarBooking booking;

  /// The selected day (decides pick-up / event / return).
  final DateTime day;

  /// True when this booking is part of a conflict on [day].
  final bool inConflict;

  /// Opens the booking details.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = CalendarRules.roleOn(booking, day);
    final details = [
      if (role != null) role.label,
      if (booking.items.isNotEmpty) booking.itemNames,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: inConflict
          ? RoundedRectangleBorder(
              side: const BorderSide(color: calendarConflictColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        onTap: onTap,
        title: Text('${booking.booking.referenceNo} · ${booking.customerName}'),
        subtitle: Text(details),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip.booking(CalendarRules.displayStatus(booking)),
            if (inConflict) ...[
              const SizedBox(height: 4),
              const StatusChip(
                label: 'Conflict',
                color: calendarConflictColor,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
