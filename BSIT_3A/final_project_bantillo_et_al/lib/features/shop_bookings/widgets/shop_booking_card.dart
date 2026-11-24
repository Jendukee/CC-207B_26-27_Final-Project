// One booking in the staff bookings list. Display only; the screen decides
// what tapping does.
//
// Shop-side redesign (Phase 2): laid out like the customer's order card
// (My Bookings), so both sides read the same way (H4):
//
//   Ref O150-0012                          [Reserved]
//   ------------------------------------------------
//   [photo]  Ana Cruz
//            Ivory Ball Gown
//            Dec 9 – Dec 11, 2026 (event Dec 10)
//            Paid ₱875.00 · Balance ₱875.00
//
// The selected card (side panel on wide screens) gets a maroon border, not
// only a color change (H1, accessibility).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
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
    final photo = booking.items.isEmpty ? null : booking.items.first.photoUrl;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: AppColors.maroon, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          selected: selected,
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
                    StatusChip.booking(BookingRules.effectiveStatus(row)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox.square(
                        dimension: 64,
                        child: photo == null
                            ? _noPhoto(theme)
                            : Image.network(
                                photo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _noPhoto(theme),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.customerName,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (booking.items.isNotEmpty)
                            Text(
                              booking.itemNames,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.dateRange(row.pickupDate, row.returnDate)}'
                            ' (event ${Formatters.date(row.eventDate)})',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Paid ${Formatters.peso(row.amountPaid)} · '
                            'Balance ${Formatters.peso(row.balance)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: row.balance > 0
                                  ? AppColors.deepRed
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPhoto(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(Icons.checkroom, color: theme.colorScheme.onSurfaceVariant),
  );
}
