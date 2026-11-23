// One row of the staff bookings list: reference number, customer, event
// date, items, payment status and a StatusChip. Display only; the screen
// decides what tapping does.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_bookings/models/booking_rules.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking.dart';

/// A card summarizing one booking.
class ShopBookingCard extends StatelessWidget {
  /// Creates the card. [selected] highlights it in the wide layout.
  const ShopBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.selected = false,
  });

  /// The booking to show.
  final ShopBooking booking;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// True when this booking is open in the side panel.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final row = booking.booking;
    final theme = Theme.of(context);
    final paymentLabel = BookingRules.paymentStatusLabel(row);
    final balanceText = row.balance > 0
        ? ' · ${Formatters.peso(row.balance)} due'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.referenceNo, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(booking.customerName),
                    const SizedBox(height: 2),
                    Text(
                      'Event: ${Formatters.date(row.eventDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (booking.items.isNotEmpty)
                      Text(
                        booking.itemNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '$paymentLabel$balanceText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.booking(BookingRules.effectiveStatus(row)),
            ],
          ),
        ),
      ),
    );
  }
}
