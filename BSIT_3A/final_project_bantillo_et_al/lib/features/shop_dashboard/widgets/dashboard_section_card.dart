// One dashboard alert list: the section title, then its bookings. It shows
// its own loading, empty and error (with Retry) states, so one failing
// section does not hide the others.
//
// Shop-side redesign (Phase 2): the same look as the customer side. The
// list sits in a white SectionCard with a "View all" link in its heading,
// each booking is a small card like My Bookings (reference + StatusChip on
// top, customer and the detail line below), and loading shows grey
// skeleton cards instead of a spinner (H1, H4). The count moved to the
// summary tiles at the top of the screen.
//
// Display only: the screen passes in the Future (from the service) and
// decides what tapping does.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/list_skeleton.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';

/// An alert list for one dashboard section.
class DashboardSectionCard extends StatelessWidget {
  /// Creates the card.
  const DashboardSectionCard({
    super.key,
    required this.section,
    required this.future,
    required this.now,
    required this.onOpenList,
    required this.onOpenBooking,
    required this.onRetry,
    this.maxRows = 5,
  });

  /// Which section this is.
  final DashboardSection section;

  /// The bookings, loading.
  final Future<List<DashboardBooking>> future;

  /// The time the data was loaded for (for "days late" etc.).
  final DateTime now;

  /// Opens the filtered bookings list.
  final VoidCallback onOpenList;

  /// Opens one booking's details.
  final ValueChanged<String> onOpenBooking;

  /// Reloads only this section.
  final VoidCallback onRetry;

  /// How many bookings to list before "View all".
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: section.title,
      icon: section.icon,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      trailing: TextButton(
        onPressed: onOpenList,
        child: const Text('View all'),
      ),
      child: FutureBuilder<List<DashboardBooking>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ListSkeleton(
              count: 2,
              showPhoto: false,
              padding: EdgeInsets.only(right: 8),
            );
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error is DashboardException
                  ? (snapshot.error! as DashboardException).message
                  : 'Could not load this section. Please try again.',
              onRetry: onRetry,
            );
          }
          final bookings = snapshot.requireData;
          if (bookings.isEmpty) return _empty(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in bookings.take(maxRows)) _row(context, item),
              if (bookings.length > maxRows)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenList,
                    child: Text('View all ${bookings.length}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// A short empty line (a full EmptyView would be too tall in a list of
  /// five sections).
  Widget _empty(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, bottom: 4),
    child: Row(
      children: [
        Icon(
          Icons.event_available_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(section.emptyMessage)),
      ],
    ),
  );

  /// One booking as a small card, like My Bookings.
  Widget _row(BuildContext context, DashboardBooking item) {
    final theme = Theme.of(context);
    final b = item.booking;
    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => onOpenBooking(b.id),
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
                  StatusChip.booking(b.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.customerName, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                DashboardDates.detailFor(section, b, now),
                style: section == DashboardSection.overdueReturns
                    ? const TextStyle(
                        color: AppColors.deepRed,
                        fontWeight: FontWeight.w600,
                      )
                    : theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
