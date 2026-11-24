// Small progress header for the reservation flow. The customer redesign
// (Phase 1) turned the flow into Date -> Checkout -> Submitted, so the
// labels are now passed in; the default keeps the old 3-step labels for
// the older step screens.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

/// Shows progress through the reservation steps (1-based [step]).
class ReservationStepIndicator extends StatelessWidget {
  /// Creates the header.
  const ReservationStepIndicator({
    super.key,
    required this.step,
    this.labels = const ['Date', 'Measurements', 'Review'],
  });

  /// Current step, starting at 1.
  final int step;

  /// One label per step.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Semantics(
        label: 'Step $step of ${labels.length}: ${labels[step - 1]}',
        excludeSemantics: true,
        child: Row(
          children: [
            for (var index = 1; index <= labels.length; index++)
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: index <= step
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: index <= step
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      // Finished steps show a tick, not just a color.
                      child: index < step
                          ? const Icon(Icons.check, size: 16)
                          : Text('$index'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index - 1],
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
