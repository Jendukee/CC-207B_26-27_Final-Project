// "Booking status" card: the FIRST card on the customer and the staff booking
// details (customer redesign 2, Phase 1). The status used to be a banner in
// the header; now the header only names the screen and the reference, and
// everything about the status sits together here:
//
//   [StatusChip]  status in words ("Waiting for your payment")
//   what happens next / what to do next, in plain language
//   Payment deadline: Dec 8, 2026, 11:59 PM        (when there is one)
//   o Requested  Nov 24, 2026, 10:02 AM
//   o Reserved   Not yet
//   o Picked up  Not yet
//   o Returned   Not yet
//   [one action for this status, e.g. "How to pay" / "Contact the shop"]
//
// Each feature passes its own wording and action, so this widget has no
// business rules.
//
// Heuristics: H1 visibility of system status, H2 match with the real world
// (plain language), H8 minimalist design (one card, one action).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// One step of the status timeline; [date] is null while not reached.
typedef StatusTimelineStep = ({String label, DateTime? date});

/// The status card.
class BookingStatusCard extends StatelessWidget {
  /// Creates the card.
  const BookingStatusCard({
    super.key,
    required this.status,
    required this.statusText,
    required this.nextStep,
    required this.steps,
    this.deadline,
    this.action,
    this.margin = const EdgeInsets.fromLTRB(8, 0, 8, 8),
  });

  /// The status to show (usually booking.displayStatus()).
  final BookingStatus status;

  /// The status in words, e.g. "Waiting for your payment".
  final String statusText;

  /// What happens next or what to do next.
  final String nextStep;

  /// Requested / Reserved / Picked up / Returned with their dates.
  final List<StatusTimelineStep> steps;

  /// Payment deadline, shown when not null.
  final DateTime? deadline;

  /// The one action for this status (a FilledButton or OutlinedButton).
  final Widget? action;

  /// Space around the card.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Booking status',
      icon: Icons.info_outline,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip.booking(status),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Live region: screen readers hear the next step after a change.
          Semantics(liveRegion: true, child: Text(nextStep)),
          if (deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Payment deadline: ${Formatters.dateTime(deadline!)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          StatusTimeline(steps: steps),
          if (action != null) ...[const SizedBox(height: 4), action!],
        ],
      ),
    );
  }
}

/// A vertical timeline: a filled check per reached step, a line between
/// steps, and the date (or "Not yet"). Text, not color alone, tells which
/// steps are done.
class StatusTimeline extends StatelessWidget {
  /// Creates the timeline.
  const StatusTimeline({super.key, required this.steps});

  /// The steps, in order.
  final List<StatusTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Icon(
                        steps[i].date != null
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: steps[i].date != null
                            ? AppColors.maroon
                            : theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      // Line down to the next step.
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i + 1].date != null
                                ? AppColors.maroon
                                : theme.dividerColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: TextStyle(
                            fontWeight: steps[i].date != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          steps[i].date != null
                              ? Formatters.dateTime(steps[i].date!)
                              : 'Not yet',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
