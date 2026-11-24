// Colored chip showing a booking status. Always shows the text label next to
// the color (accessibility).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/shared/models/booking_status.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.pending => Colors.orange,
      BookingStatus.reserved => Colors.blue,
      BookingStatus.rentedOut => Colors.purple,
      BookingStatus.returned => Colors.green,
      BookingStatus.cancelled => Colors.red,
      BookingStatus.expired => Colors.grey,
    };
    return Chip(
      label: Text(status.label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}