import 'package:flutter/material.dart';

/// Shows progress through the three reservation steps.
class ReservationStepIndicator extends StatelessWidget {
  const ReservationStepIndicator({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (var index = 1; index <= 3; index++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: index <= step
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: index <= step
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    child: Text('$index'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    const ['Date', 'Measurements', 'Review'][index - 1],
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
