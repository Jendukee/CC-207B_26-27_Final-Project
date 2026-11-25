// The "New requests since yesterday" panel of the staff Dashboard
// (dashboard design):
//
//   [NEW]  New requests since yesterday                    4   >   <- header
//   ---------------------------------------------------------------
//   Maggie Dee                                         (• Pending)  <- rows
//   O150-261124-2BD1CF
//   Nov 24, 2026 · 4:47 PM
//   ---------------------------------------------------------------
//              View all booking requests →                         <- footer
//
// * The header (count + chevron) and the footer link open the pending
//   bookings list; each row opens that booking (48 px+ targets) (H7).
// * Status is a pill with a dot AND the word ("Pending"), never color
//   only; any other status uses the shared StatusChip.
// * Loading: grey skeleton rows. Empty: "No new requests since
//   yesterday." Error: the message with Retry (H1, H9).
//
// Display only: the screen passes in the Future (same data as before) and
// decides what tapping does. No logic changed.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/list_skeleton.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/dashboard_glance_card.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// The new-requests panel.
class DashboardRequestsPanel extends StatelessWidget {
  /// Creates the panel.
  const DashboardRequestsPanel({
    super.key,
    required this.future,
    required this.now,
    required this.onOpenList,
    required this.onOpenBooking,
    required this.onRetry,
    this.maxRows = 5,
  });

  /// The section this panel shows.
  static const DashboardSection section = DashboardSection.newRequests;

  /// The new requests.
  final Future<List<DashboardBooking>> future;

  /// The time the data was loaded for.
  final DateTime now;

  /// Opens the pending bookings list.
  final VoidCallback onOpenList;

  /// Opens one booking's details.
  final ValueChanged<String> onOpenBooking;

  /// Reloads the panel.
  final VoidCallback onRetry;

  /// Rows shown before "View all booking requests".
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          final error = loading ? null : snapshot.error;
          final bookings = (loading || error != null)
              ? const <DashboardBooking>[]
              : snapshot.requireData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(loading || error != null ? null : bookings.length),
              if (loading)
                const ListSkeleton(
                  count: 3,
                  showPhoto: false,
                  padding: EdgeInsets.all(12),
                )
              else if (error != null)
                ErrorView(
                  message: error is DashboardException
                      ? error.message
                      : 'Could not load this section. Please try again.',
                  onRetry: onRetry,
                )
              else if (bookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    DashboardGlanceCard.emptyLine(section),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                for (final item in bookings.take(maxRows)) _row(item),
              _footer(),
            ],
          );
        },
      ),
    );
  }

  /// [NEW] title, count and chevron. [count] null while loading / failed.
  Widget _header(int? count) {
    final countText = count == null
        ? '–'
        : count >= ShopDashboardService.sectionLimit
        ? '$count+'
        : '$count';
    return Semantics(
      button: true,
      label: '${section.title}: $countText. View all booking requests.',
      excludeSemantics: true,
      child: Material(
        color: AppColors.panelHeader,
        child: InkWell(
          onTap: onOpenList,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 69),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chipBlush,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: AppColors.maroon,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        color: AppColors.inkDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    countText,
                    style: const TextStyle(
                      color: AppColors.inkDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.inkDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One request: name, reference, when it came in, and its status.
  Widget _row(DashboardBooking item) {
    final b = item.booking;
    final created = b.createdAt?.toLocal();
    final when = created == null
        ? DashboardDates.detailFor(section, b, now)
        : '${Formatters.date(created)} · ${DateFormat.jm().format(created)}';
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rowDivider)),
      ),
      child: InkWell(
        onTap: () => onOpenBooking(b.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.referenceNo,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        when,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (b.status == BookingStatus.pending)
                  const _PendingPill()
                else
                  StatusChip.booking(b.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "View all booking requests →".
  Widget _footer() => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.panelFooter,
      border: Border(top: BorderSide(color: AppColors.rowDivider)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: onOpenList,
          child: const Text('View all booking requests →'),
        ),
      ),
    ),
  );
}

/// "• Pending" in the design's warm pill (dot + word).
class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: Pending',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.pendingPill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.pendingDot,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 6),
            ),
            SizedBox(width: 6),
            Text(
              'Pending',
              style: TextStyle(
                color: AppColors.pendingText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
