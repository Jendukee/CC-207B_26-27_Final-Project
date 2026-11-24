// One summary card at the top of the Dashboard (shop-side redesign,
// Phase 2), in the customer side's card style: a white rounded card on the
// light grey page with an icon, the count, the label and a "View" link that
// opens the filtered bookings list.
//
//   [icon]
//   3            <- deep red when an alert section has bookings
//   Pick-ups today
//   View >
//
// It reads the SAME Future as the section's list below, so nothing is
// loaded twice; a grey block shows while it loads and "–" after an error.
//
// H1 visibility of system status (today's numbers first), H6 recognition
// (icon + label), H7 efficiency (one tap to the filtered list).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/skeleton_box.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';

/// A count card for one dashboard section.
class DashboardSummaryTile extends StatelessWidget {
  /// Creates the tile.
  const DashboardSummaryTile({
    super.key,
    required this.section,
    required this.future,
    required this.onView,
  });

  /// Which section.
  final DashboardSection section;

  /// The section's bookings (shared with its list card).
  final Future<List<DashboardBooking>> future;

  /// Opens the filtered bookings list.
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<DashboardBooking>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final count = loading || snapshot.hasError
            ? null
            : snapshot.requireData.length;
        final highlight = section.isAlert && (count ?? 0) > 0;
        final color = highlight ? AppColors.deepRed : AppColors.maroon;
        final countText = count == null
            ? '–'
            : count >= ShopDashboardService.sectionLimit
            ? '$count+'
            : '$count';

        // One screen-reader node: "Pick-ups today: 3. View bookings."
        return Semantics(
          button: true,
          label:
              '${section.title}: ${loading ? 'loading' : countText}. '
              'View bookings.',
          excludeSemantics: true,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onView,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(section.icon, color: color, size: 24),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: loading
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SkeletonBox(height: 24, width: 40),
                            )
                          : Text(
                              countText,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    Text(
                      section.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    // "View" link: the whole card is the 48 px target.
                    const SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Text(
                            'View',
                            style: TextStyle(
                              color: AppColors.maroon,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.maroon,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
