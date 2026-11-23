// Orange 150 brand palette and semantic colors.
//
// Rules (checked in code review):
// - Gold is for accents, fills and icons ONLY. Never gold text on white:
//   it fails WCAG contrast.
// - Body text is near-black. Text on maroon is white.
// - Status colors are always paired with a text label (see StatusChip).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// Named colors used across the app. Prefer these over raw hex values.
abstract final class AppColors {
  /// Brand primary. App bars, primary buttons, "Reserved" status.
  static const Color maroon = Color(0xFF7A1F2B);

  /// Darker maroon for pressed states and gradients.
  static const Color maroonDark = Color(0xFF5A1520);

  /// Brand accent. Icons, fills, borders only. Never as text on white.
  static const Color gold = Color(0xFFC9A227);

  /// Very light gold fill (selection indicators, AI badge background).
  static const Color goldTint = Color(0xFFF7EFD6);

  /// Errors, booking conflicts, "Rented Out" status.
  static const Color deepRed = Color(0xFFA4161A);

  /// Warnings and "Pending" status. Dark enough for white text (AA).
  static const Color warningOrange = Color(0xFFC2410C);

  /// Success and "Returned" status.
  static const Color success = Color(0xFF2E7D32);

  /// Neutral grey for "Cancelled" and "Expired" status.
  static const Color neutralGrey = Color(0xFF616161);

  /// App background.
  static const Color background = Colors.white;

  /// Main body text (near-black).
  static const Color textPrimary = Color(0xFF1C1B1F);

  /// Secondary text (still passes AA on white).
  static const Color textSecondary = Color(0xFF49454F);

  /// Text and icons placed on maroon surfaces.
  static const Color onMaroon = Colors.white;
}
