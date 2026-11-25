// One "Today at a glance" card on the staff Dashboard (dashboard design):
//
//   [icon]  Pick-ups today                              [View more]
//           Your next confirmed pick-up will appear here.
//   ------------------------------------------------------------------
//   Maria Santos                 Ref O150-0012          [Reserved]    <- only
//   Event Dec 10, 2026                                                  when
//                                                                       there
//                                                                       are any
//
// * White card, thin border, 16 px corners, a tinted icon square per
//   section (icon + text label, never color only) (H6).
// * The second line is a friendly message when the section is empty, or
//   the count ("3 bookings", deep red for overdue / expiring) otherwise
//   (H1). Up to [maxRows] bookings are listed under it; each opens its
//   details. "View more" (the whole top row, 48 px+) opens the filtered
//   bookings list.
// * Loading: a grey line instead of the message. Error: the message with
//   a Retry button, so one failing card does not hide the others (H9).
//
// Display only: the screen passes in the Future (same data as before) and
// decides what tapping does. No logic changed.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/skeleton_box.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';

/// A glance card for one dashboard section.
class DashboardGlanceCard extends StatelessWidget {
  /// Creates the card.
  const DashboardGlanceCard({
    super.key,
    required this.section,
    required this.future,
    required this.now,
    required this.onOpenList,
    required this.onOpenBooking,
    required this.onRetry,
    this.maxRows = 3,
  });

  /// Which section.
  final DashboardSection section;

  /// The section's bookings (shared with its summary tile).
  final Future<List<DashboardBooking>> future;

  /// The time the data was loaded for (for "days late" etc.).
  final DateTime now;

  /// Opens the filtered bookings list ("View more").
  final VoidCallback onOpenList;

  /// Opens one booking's details.
  final ValueChanged<String> onOpenBooking;

  /// Reloads only this section.
  final VoidCallback onRetry;

  /// Bookings listed under the summary before "View more".
  final int maxRows;

  /// The design's friendly line when a section is empty.
  static String emptyLine(DashboardSection section) => switch (section) {
    DashboardSection.pickupsToday =>
      'Your next confirmed pick-up will appear here.',
    DashboardSection.overdueReturns =>
      'No items are due back at the studio today.',
    DashboardSection.returnsToday => 'Everything is right where it should be.',
    DashboardSection.expiringSoon => 'You have a little more breathing room.',
    DashboardSection.newRequests => 'No new requests since yesterday.',
  };

  /// Icon square tint and icon color per section.
  static (Color, Color) colorsFor(
    DashboardSection section,
  ) => switch (section) {
    DashboardSection.pickupsToday => (AppColors.tintPink, AppColors.maroon),
    DashboardSection.overdueReturns => (AppColors.tintPeach, AppColors.deepRed),
    DashboardSection.returnsToday => (AppColors.tintMint, AppColors.success),
    DashboardSection.expiringSoon => (AppColors.tintMauve, AppColors.maroon),
    DashboardSection.newRequests => (AppColors.tintPink, AppColors.maroon),
  };

  @override
  Widget build(BuildContext context) {
    final (tint, iconColor) = colorsFor(section);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<List<DashboardBooking>>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final failed = !loading && snapshot.hasError;
          final bookings = (loading || failed)
              ? const <DashboardBooking>[]
              : snapshot.requireData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(
                context,
                tint,
                iconColor,
                loading,
                failed ? snapshot.error : null,
                bookings,
              ),
              for (final item in bookings.take(maxRows)) ...[
                const Divider(height: 1, color: AppColors.rowDivider),
                _bookingRow(context, item),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Icon, title, summary line and "View more" (the whole row is the
  /// target).
  Widget _header(
    BuildContext context,
    Color tint,
    Color iconColor,
    bool loading,
    Object? error,
    List<DashboardBooking> bookings,
  ) {
    final count = bookings.length;
    final countText = count >= ShopDashboardService.sectionLimit
        ? '$count+'
        : '$count';
    final summary = count == 0
        ? emptyLine(section)
        : '$countText ${count == 1 ? 'booking' : 'bookings'}';
    final alert = section.isAlert && count > 0;
    final failed = error != null;

    return Semantics(
      button: true,
      label:
          '${section.title}: '
          '${loading ? 'loading' : (failed ? 'could not load' : summary)}. '
          'View more.',
      excludeSemantics: !failed, // keep the Retry button reachable
      child: InkWell(
        onTap: onOpenList,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 108),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(section.icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          color: AppColors.inkDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (loading)
                        const SkeletonBox(height: 14, width: 180)
                      else if (failed)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _errorText(error),
                              style: const TextStyle(
                                color: AppColors.deepRed,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else
                        Text(
                          summary,
                          style: TextStyle(
                            color: alert
                                ? AppColors.deepRed
                                : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: alert
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const _ViewMoreChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The service's message (DashboardException), or a general one.
  String _errorText(Object? error) => error is DashboardException
      ? error.message
      : 'Could not load this section. Please try again.';

  /// One booking: customer, reference and detail, with its status chip.
  Widget _bookingRow(BuildContext context, DashboardBooking item) {
    final b = item.booking;
    return InkWell(
      onTap: () => onOpenBooking(b.id),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        color: AppColors.inkDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref ${b.referenceNo} · '
                      '${DashboardDates.detailFor(section, b, now)}',
                      style: TextStyle(
                        color: section == DashboardSection.overdueReturns
                            ? AppColors.deepRed
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.booking(b.status),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small "View more" chip (visual only: its card row is the target).
class _ViewMoreChip extends StatelessWidget {
  const _ViewMoreChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBlush,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'View more',
        style: TextStyle(
          color: AppColors.maroon,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
