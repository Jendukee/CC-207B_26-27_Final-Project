// One summary card in the Dashboard hero (staff dashboard design): a white
// rounded card on the maroon-to-red hero with the section icon on a pink
// square, the count and the label. Tapping it opens the filtered bookings
// list.
//
//   Wide tile (>= 180 px)        Narrow tile (phones)
//   [icon]  3                    [icon]
//           Pick-ups today       3
//                                Pick-ups today
//
// * The count turns deep red when an alert section has bookings.
// * It reads the SAME Future as the section's list below, so nothing is
//   loaded twice; a grey block shows while it loads and "–" after an error.
// * The design has no "View" text: the whole card is the (48 px+) target,
//   and screen readers hear "Pick-ups today: 3. View bookings."
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

  /// Tiles narrower than this stack the icon above the count.
  static const double sideBySideWidth = 180;

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
        final color = highlight ? AppColors.deepRed : AppColors.maroonDeep;
        final countText = count == null
            ? '–'
            : count >= ShopDashboardService.sectionLimit
            ? '$count+'
            : '$count';

        final icon = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.blushIcon,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(section.icon, color: color, size: 22),
        );

        final numbers = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        );

        // One screen-reader node: "Pick-ups today: 3. View bookings."
        return Semantics(
          button: true,
          label:
              '${section.title}: ${loading ? 'loading' : countText}. '
              'View bookings.',
          excludeSemantics: true,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onView,
              child: ConstrainedBox(
                // The design's 106 px card height.
                constraints: const BoxConstraints(minHeight: 106),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= sideBySideWidth - 24) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(child: numbers),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [icon, const SizedBox(height: 8), numbers],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
