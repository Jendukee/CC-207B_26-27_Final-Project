// Splash screen shown while the saved Supabase session and role load.
//
// It does not navigate by itself: AuthGuard keeps the app here until
// SessionController.isReady, then redirects guests/customers to Browse
// and staff/owners to Dashboard (or to the `from` link they opened).
//
// OWNER: team lead.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Branded loading screen.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.maroon,
      body: Center(
        child: Semantics(
          label: 'Orange 150 is loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checkroom, size: 72, color: AppColors.gold),
              const SizedBox(height: 16),
              Text(
                'Orange 150',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.onMaroon,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gown & Suit Rentals',
                style:
                    textTheme.titleMedium?.copyWith(color: AppColors.onMaroon),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
