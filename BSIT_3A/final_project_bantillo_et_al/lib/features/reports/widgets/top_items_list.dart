// Ranked list of the most-rented items: rank, name, type and size, the
// number of rentals, and a bar showing it relative to the top item.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/reports/models/report_data.dart';

/// The ranking.
class TopItemsList extends StatelessWidget {
  /// Creates the list. [items] must be sorted highest first.
  const TopItemsList({super.key, required this.items});

  /// Items, highest first.
  final List<TopItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = items.isEmpty ? 1 : items.first.rentals;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Rank badge: gold for #1 (with the number, not color alone).
                CircleAvatar(
                  radius: 16,
                  backgroundColor: i == 0
                      ? AppColors.gold
                      : theme.colorScheme.secondaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: i == 0
                          ? AppColors.textPrimary
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].name, style: theme.textTheme.bodyLarge),
                      Text(
                        [
                          items[i].type.label,
                          if (items[i].size.isNotEmpty) 'size ${items[i].size}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: top == 0 ? 0 : items[i].rentals / top,
                        minHeight: 6,
                        color: AppColors.maroon,
                        backgroundColor: AppColors.maroon.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${items[i].rentals} '
                  '${items[i].rentals == 1 ? 'rental' : 'rentals'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
