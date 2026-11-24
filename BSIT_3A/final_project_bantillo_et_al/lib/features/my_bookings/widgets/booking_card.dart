// One booking in the My Bookings tabs, like an order card (customer
// redesign, Phase 1): item photo, name, rental dates, StatusChip, amount
// paid and balance, the payment deadline when pending, and ONE context
// button that fits the tab (e.g. "View payment details" on To Pay).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_formatters.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_status_badge.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.myBooking,
    required this.onTap,
    this.onAction,
  });

  final MyBooking myBooking;

  /// Opens the booking details (whole card).
  final VoidCallback onTap;

  /// The context button. Defaults to [onTap] when null.
  final VoidCallback? onAction;

  /// Context button text for each tab.
  static String actionLabel(CustomerBookingTab tab) => switch (tab) {
    CustomerBookingTab.toPay => 'View payment details',
    CustomerBookingTab.toPickUp => 'View pick-up details',
    CustomerBookingTab.rented => 'View return date',
    CustomerBookingTab.completed => 'View booking',
    CustomerBookingTab.cancelled => 'Book again',
  };

  @override
  Widget build(BuildContext context) {
    final b = myBooking.booking;
    final theme = Theme.of(context);
    final tab = CustomerBookingTab.of(b);
    final photo =
        myBooking.items.isEmpty || myBooking.items.first.photoUrls.isEmpty
        ? null
        : myBooking.items.first.photoUrls.first;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      elevation: 0,
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
                      'Ref ${b.referenceNo}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  BookingStatusBadge(status: b.displayStatus()),
                ],
              ),
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 72,
                      child: photo == null
                          ? ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.checkroom),
                            )
                          : Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.checkroom),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myBooking.itemNames,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDate(b.pickupDate)} – '
                          '${formatDate(b.returnDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paid ${formatPeso(b.amountPaid)} · '
                          'Balance ${formatPeso(b.balance)}',
                        ),
                        if (payByText(b) != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            payByText(b)!,
                            style: const TextStyle(
                              color: AppColors.deepRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onAction ?? onTap,
                  child: Text(actionLabel(tab)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
