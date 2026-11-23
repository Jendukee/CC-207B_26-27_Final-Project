// Colored status chip that ALWAYS shows a text label (never color only,
// so it works for color-blind users and screen readers).
//
// Booking colors: Pending = orange, Reserved = maroon, Rented Out = deep
// red, Returned = green, Cancelled / Expired = grey.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// A pill with white text on a solid color.
class StatusChip extends StatelessWidget {
  /// Creates a chip with any [label] and [color]. Pick a [color] dark
  /// enough for white text (all AppColors status colors are).
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Chip for a booking status, using the standard color mapping.
  factory StatusChip.booking(BookingStatus status, {Key? key}) {
    return StatusChip(key: key, label: status.label, color: colorFor(status));
  }

  /// Text shown inside the chip (required: color is never enough alone).
  final String label;

  /// Background color.
  final Color color;

  /// Optional leading icon.
  final IconData? icon;

  /// Standard color for each booking status.
  static Color colorFor(BookingStatus status) => switch (status) {
        BookingStatus.pending => AppColors.warningOrange,
        BookingStatus.reserved => AppColors.maroon,
        BookingStatus.rentedOut => AppColors.deepRed,
        BookingStatus.returned => AppColors.success,
        BookingStatus.cancelled => AppColors.neutralGrey,
        BookingStatus.expired => AppColors.neutralGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
