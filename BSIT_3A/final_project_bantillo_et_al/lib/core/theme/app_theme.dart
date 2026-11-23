// Material 3 theme for the app, built from AppColors.
//
// - Maroon primary with white text, gold secondary used only for fills/icons.
// - 48 px minimum touch targets on buttons and padded tap targets.
// - Near-black, readable body text (16 px body).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Builds the [ThemeData] used by MaterialApp.
abstract final class AppTheme {
  /// Minimum size for any tappable control (Material accessibility guideline).
  static const Size minTouchTarget = Size(48, 48);

  /// The light theme (the app has no dark theme yet).
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.maroon,
      onPrimary: AppColors.onMaroon,
      secondary: AppColors.gold,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.goldTint,
      onSecondaryContainer: AppColors.textPrimary,
      error: AppColors.deepRed,
      onError: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.onMaroon,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.onMaroon,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: AppColors.maroon,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minTouchTarget,
          foregroundColor: AppColors.maroon,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minTouchTarget),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.goldTint,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.goldTint,
        selectedIconTheme: IconThemeData(color: AppColors.maroon),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
