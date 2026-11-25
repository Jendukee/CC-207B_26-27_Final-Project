// The top of the staff Dashboard (staff dashboard design): a rounded card
// with a dark maroon to red gradient holding the greeting, today's date, a
// white "View calendar" button and the five summary tiles.
//
//   Hi, Pearl Batumbakal                       [View calendar]
//   Today is Nov 24, 2026
//   [tile] [tile] [tile] [tile] [tile]
//
// * Tiles: 5 per row from 1000 px of card width, 3 from 600, else 2.
// * Phones: the button moves under the date, so nothing is squeezed.
// * White text sits on the dark left end (about 18:1); even the red right
//   end passes AA for white (about 4.7:1).
//
// Display only: the screen passes the texts, the tiles and what the button
// does.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// The gradient greeting card with the summary tiles.
class DashboardHero extends StatelessWidget {
  /// Creates the card.
  const DashboardHero({
    super.key,
    required this.greeting,
    required this.dateLine,
    required this.onViewCalendar,
    required this.tiles,
  });

  /// e.g. "Hi, Pearl Batumbakal".
  final String greeting;

  /// e.g. "Today is Nov 24, 2026".
  final String dateLine;

  /// Opens the Calendar tab.
  final VoidCallback onViewCalendar;

  /// The summary tiles, in order.
  final List<Widget> tiles;

  /// Card width from which the button sits beside the greeting.
  static const double wideWidth = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideWidth;
        final pad = wide ? 32.0 : 16.0;
        final inner = constraints.maxWidth - pad * 2;

        final texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                greeting,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 30 : 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.75,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateLine,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: wide ? 18 : 16,
              ),
            ),
          ],
        );

        final button = OutlinedButton.icon(
          onPressed: onViewCalendar,
          icon: const Icon(Icons.calendar_month_outlined, size: 20),
          label: const Text('View calendar'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textOnSoft,
            side: const BorderSide(color: AppColors.outlineSoft),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        final perRow = inner >= 1000
            ? 5
            : inner >= 600
            ? 3
            : 2;
        final gap = wide ? 20.0 : 8.0;
        final tileWidth = (inner - gap * (perRow - 1)) / perRow;

        return Container(
          padding: EdgeInsets.fromLTRB(pad, pad - 4, pad, pad),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.heroStart, AppColors.heroEnd],
            ),
            borderRadius: BorderRadius.circular(wide ? 25 : 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: texts),
                    const SizedBox(width: 16),
                    button,
                  ],
                )
              else ...[
                texts,
                const SizedBox(height: 12),
                button,
              ],
              SizedBox(height: wide ? 28 : 16),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: tileWidth, child: tile),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
