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

  // ---- Staff dashboard design (shop side) --------------------------------
  // Contrast checked against the surface each one sits on (WCAG AA).

  /// Very dark maroon: the staff sidebar and the Dashboard header.
  static const Color maroonDeep = Color(0xFF480B17);

  /// Light blush page behind the staff Dashboard cards.
  static const Color blush = Color(0xFFFEF6F6);

  /// Dashboard hero gradient, left (dark) end. White text: about 18:1.
  static const Color heroStart = Color(0xFF390101);

  /// Dashboard hero gradient, right (red) end. White text: about 4.7:1.
  static const Color heroEnd = Color(0xFFD33A3D);

  /// Pink square behind the summary tile icons (maroon icon on it: 8.6:1).
  static const Color blushIcon = Color(0xFFF1AEBB);

  /// Muted text and icons on [maroonDeep] (about 10:1).
  static const Color onMaroonMuted = Color(0xFFD4D4D4);

  /// Thin borders and dividers on [maroonDeep].
  static const Color sidebarBorder = Color(0xFF3F3F3F);

  /// The initials circle in the sidebar account footer (white text: 7.8:1).
  static const Color avatarGrey = Color(0xFF525252);

  /// Soft border of white buttons on the hero (e.g. "View calendar").
  static const Color outlineSoft = Color(0xFFE7E2E3);

  /// Dark text on those white hero buttons (about 12:1 on white).
  static const Color textOnSoft = Color(0xFF403539);

  // ---- Staff dashboard "Today at a glance" and "New requests" ------------

  /// Headings and names on the glance cards (about 16:1 on white).
  static const Color inkDark = Color(0xFF292126);

  /// Muted lines on the glance cards (about 7.8:1 on white).
  static const Color textMuted = Color(0xFF525252);

  /// Thin border of the glance cards and the requests panel.
  static const Color cardBorder = Color(0xFFE9E3E5);

  /// Divider between request rows.
  static const Color rowDivider = Color(0xFFEEE8EA);

  /// "View more" / "NEW" chip; maroon text on it is about 7.7:1.
  static const Color chipBlush = Color(0xFFEADDDF);

  /// Icon square tints (icons on them are 3:1 or more).
  static const Color tintPink = Color(0xFFF0E1E4);

  /// Icon square tint for overdue returns.
  static const Color tintPeach = Color(0xFFF6E7DC);

  /// Icon square tint for returns today.
  static const Color tintMint = Color(0xFFDFEBE7);

  /// Icon square tint for expiring requests.
  static const Color tintMauve = Color(0xFFEEE4E9);

  /// Header band of the "New requests" panel.
  static const Color panelHeader = Color(0xFFF1E8DC);

  /// Footer band of the "New requests" panel.
  static const Color panelFooter = Color(0xFFFDFAFB);

  /// "Pending" pill background (its text is about 5.7:1 on it).
  static const Color pendingPill = Color(0xFFF4E9DF);

  /// The dot in the "Pending" pill.
  static const Color pendingDot = Color(0xFF95613A);

  /// "Pending" pill text.
  static const Color pendingText = Color(0xFF80502D);
}
