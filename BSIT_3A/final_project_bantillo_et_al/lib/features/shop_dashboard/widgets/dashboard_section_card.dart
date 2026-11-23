// One dashboard card: a count, a title and the list of bookings under it.
// It shows its own loading, empty and error (with Retry) states, so one
// failing section does not hide the others.
//
// Display only: the screen passes in the Future (from the service) and
// decides what tapping does.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_booking.dart';
import 'package:orange150_rental/features/shop_dashboard/models/dashboard_section.dart';
import 'package:orange150_rental/features/shop_dashboard/services/shop_dashboard_service.dart';

/// A summary card with an alert list.
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<List<DashboardBooking>>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final bookings = snapshot.data ?? const <DashboardBooking>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, loading || snapshot.hasError ? null : bookings),
              const Divider(height: 1),
              if (loading)
                const Padding(padding: EdgeInsets.all(16), child: LoadingView())
              else if (snapshot.hasError)
                ErrorView(
                  message: snapshot.error is DashboardException
                      ? (snapshot.error! as DashboardException).message
                      : 'Could not load this section. Please try again.',
                  onRetry: onRetry,
                )
              else if (bookings.isEmpty)
                EmptyView(
                  icon: Icons.event_available_outlined,
                  message: section.emptyMessage,
                )
              else
                ..._rows(context, bookings),
            ],
          );
        },
      ),
    );
  }

  /// Big count + title. Tapping opens the filtered bookings list.
  /// [bookings] is null while loading or after an error.
  Widget _header(BuildContext context, List<DashboardBooking>? bookings) {
    final theme = Theme.of(context);
    final count = bookings?.length;
    final highlight = section.isAlert && (count ?? 0) > 0;
    final color = highlight ? AppColors.deepRed : theme.colorScheme.primary;
    final countText = count == null
        ? '–'
        : count >= ShopDashboardService.sectionLimit
        ? '$count+'
        : '$count';

    return Semantics(
      button: true,
      label: '${section.title}: ${count ?? 'loading'}. Open bookings list.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpenList,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(section.icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(section.title, style: theme.textTheme.titleMedium),
              ),
              Text(
                countText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  /// Up to [maxRows] bookings, then a "View all" link.
  List<Widget> _rows(BuildContext context, List<DashboardBooking> bookings) {
    final shown = bookings.take(maxRows);
    return [
      for (final item in shown)
        ListTile(
          onTap: () => onOpenBooking(item.booking.id),
          title: Text('${item.booking.referenceNo} · ${item.customerName}'),
          subtitle: Text(
            DashboardDates.detailFor(section, item.booking, now),
            style: section == DashboardSection.overdueReturns
                ? const TextStyle(color: AppColors.deepRed)
                : null,
          ),
          trailing: StatusChip.booking(item.booking.status),
        ),
      if (bookings.length > maxRows)
        TextButton(
          onPressed: onOpenList,
          child: Text('View all ${bookings.length}'),
        ),
    ];
  }
}
