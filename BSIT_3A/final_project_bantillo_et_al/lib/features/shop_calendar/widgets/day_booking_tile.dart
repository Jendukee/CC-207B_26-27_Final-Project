// One booking in the selected day's list: reference, customer, what the
// day is for it (pick-up / event / return), items, a StatusChip and a red
// "Conflict" chip when it clashes with another booking.
//
// Shop-side redesign (Phase 2): drawn as a booking card like My Bookings
// and the staff bookings list (reference + chips on top, a divider, then
// the customer, "Pick-up day · Ivory Ball Gown" and the rental dates), so
// the same booking looks the same everywhere (H4). A conflict adds a red
// border AND the "Conflict" chip (not color alone).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_legend.dart';

/// A tappable booking card.
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
    final theme = Theme.of(context);
    final row = booking.booking;
    final role = CalendarRules.roleOn(booking, day);
    final details = [
      if (role != null) role.label,
      if (booking.items.isNotEmpty) booking.itemNames,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: inConflict
            ? const BorderSide(color: calendarConflictColor, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ref ${row.referenceNo}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (inConflict)
                        const StatusChip(
                          label: 'Conflict',
                          color: calendarConflictColor,
                          icon: Icons.warning_amber_rounded,
                        ),
                      StatusChip.booking(CalendarRules.displayStatus(booking)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(booking.customerName, style: theme.textTheme.titleSmall),
              if (details.isNotEmpty)
                Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                Formatters.dateRange(row.pickupDate, row.returnDate),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
