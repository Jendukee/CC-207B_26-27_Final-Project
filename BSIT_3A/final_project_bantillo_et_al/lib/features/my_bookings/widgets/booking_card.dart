// One row in the My Bookings list.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_formatters.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.myBooking, required this.onTap});

  final MyBooking myBooking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = myBooking.booking;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myBooking.itemNames,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${b.referenceNo}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Event: ${formatDate(b.eventDate)}'),
                    const SizedBox(height: 4),
                    Text('Total: ${formatPeso(b.totalAmount)}'),
                    // UI audit #8: pending requests show their deadline.
                    if (payByText(b) != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        payByText(b)!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusBadge(status: b.displayStatus()),
            ],
          ),
        ),
      ),
    );
  }
}
