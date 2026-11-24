// "Reserve Now" bottom sheet (customer redesign, Phase 1), like the
// variation picker of a shopping app: pick the EVENT date on an
// availability calendar (unavailable dates blocked), see the 3-day rental
// window (pick-up, event, return), then press Continue.
//
// Usage:
//   final date = await showReserveDateSheet(context, ...);
//   if (date != null) // open checkout for that date
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/catalog/widgets/availability_calendar.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Opens the sheet; returns the chosen event date, or null if closed.
Future<DateTime?> showReserveDateSheet(
  BuildContext context, {
  required Item item,
  required Set<DateTime> blockedDays,
  required DateTime earliest,
  required DateTime latest,
  DateTime? initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReserveDateSheet(
      item: item,
      blockedDays: blockedDays,
      earliest: earliest,
      latest: latest,
      initial: initial,
    ),
  );
}

class _ReserveDateSheet extends StatefulWidget {
  const _ReserveDateSheet({
    required this.item,
    required this.blockedDays,
    required this.earliest,
    required this.latest,
    this.initial,
  });

  final Item item;
  final Set<DateTime> blockedDays;
  final DateTime earliest;
  final DateTime latest;
  final DateTime? initial;

  @override
  State<_ReserveDateSheet> createState() => _ReserveDateSheetState();
}

class _ReserveDateSheetState extends State<_ReserveDateSheet> {
  late DateTime? _event = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = _event;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  'Choose your event date',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item.name} · Size ${widget.item.size}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rental is 3 days: pick-up the day before, the event, and '
                  'return the day after. Booked dates are struck through.',
                ),
                const SizedBox(height: 8),
                AvailabilityCalendar(
                  blockedDays: widget.blockedDays,
                  earliest: widget.earliest,
                  latest: widget.latest,
                  selected: event,
                  onSelect: (date) => setState(() => _event = date),
                ),
                const SizedBox(height: 12),
                // The 3-day window.
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _windowDay(
                          'Pick-up',
                          event?.subtract(const Duration(days: 1)),
                        ),
                        _windowDay('Event', event),
                        _windowDay(
                          'Return',
                          event?.add(const Duration(days: 1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          StickyActionBar(
            message: event == null ? 'Tap a free date to continue.' : null,
            action: FilledButton(
              onPressed: event == null
                  ? null
                  : () => Navigator.of(context).pop(event),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowDay(String label, DateTime? date) => Expanded(
    child: Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          date == null ? '—' : Formatters.date(date),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
