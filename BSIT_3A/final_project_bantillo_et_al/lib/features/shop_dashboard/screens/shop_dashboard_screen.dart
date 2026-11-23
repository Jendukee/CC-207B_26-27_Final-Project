// Staff dashboard: today's pickups and returns, pending bookings awaiting
// payment, overdue returns and items in cleaning/repair, as tappable cards.
//
// OWNER: Member 3. Skeleton placeholder: replace the body with your own
// implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

/// Placeholder for the "Dashboard" screen (see the file header for the plan).
class ShopDashboardScreen extends StatelessWidget {
  /// Creates the "Dashboard" screen.
  const ShopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO: Member 3 builds this',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
