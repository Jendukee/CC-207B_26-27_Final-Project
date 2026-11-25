// The staff side menu on wide screens (staff dashboard design):
//
//   [logo] Orange 150        <- dark maroon panel, 238 px wide
//          WORKSPACE
//   MANAGEMENT
//   [#] Dashboard            <- selected: white pill, dark text
//   [#] Calendar             <- others: light grey on maroon
//   ...
//   ------------------------------
//   (PB) Pearl Batumbakal    <- who is signed in
//        Staff account
//
// * Display + navigation only: tapping an item calls [onSelect], exactly
//   like the NavigationRail it replaces (same branches, same order).
// * The signed-in name and role come from SessionController (no new
//   queries). The design's "Bookings" count badge and "All caught up" card
//   need extra database reads, so they are left out (no logic changes).
// * Every item is 48 px tall with a text label (no icon-only items) and is
//   announced as a selected / unselected button (H4, H6; WCAG AA contrast,
//   see AppColors).
//
// Used by ResponsiveScaffold from ResponsiveScaffold.sidebarBreakpoint.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// One item of [BrandSidebar].
typedef BrandSidebarItem = ({
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// The white rounded square with the maroon Orange 150 mark (the sidebar
/// and rail logo). Maroon on white is used because gold on white is below
/// 3:1. Not a button.
class BrandLogoTile extends StatelessWidget {
  /// Creates the tile. Give [semanticLabel] when no "Orange 150" text is
  /// shown next to it.
  const BrandLogoTile({super.key, this.size = 36, this.semanticLabel});

  /// Width and height.
  final double size;

  /// Read by screen readers; null when the name is written beside it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom,
        size: size * 0.6,
        color: AppColors.maroonDeep,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// The dark maroon side menu used by the staff shell on wide screens.
class BrandSidebar extends StatelessWidget {
  /// Creates the menu.
  const BrandSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.sectionLabel = 'MANAGEMENT',
  });

  /// Sidebar width (from the design).
  static const double width = 238;

  /// Menu items, in branch order.
  final List<BrandSidebarItem> items;

  /// The current branch.
  final int selectedIndex;

  /// Called with the tapped item's index.
  final ValueChanged<int> onSelect;

  /// Small heading above the items.
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.maroonDeep,
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                child: Text(
                  sectionLabel,
                  style: const TextStyle(
                    color: AppColors.onMaroonMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              // Scrolls if a short window cannot fit every item.
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) => _Item(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
              ),
              const _AccountFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo, "Orange 150" and "WORKSPACE".
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 115,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            BrandLogoTile(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orange 150',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.onMaroon,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'WORKSPACE',
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.onMaroonMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
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

/// One 48 px menu item.
class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BrandSidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.onMaroonMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          // Visible on the dark panel (the default splash is too faint).
          hoverColor: Colors.white.withValues(alpha: 0.08),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 20,
                    color: selected ? AppColors.maroonDeep : color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Initials, name and account type of the signed-in user. Rebuilds when
/// the session changes (e.g. the name loads after sign in).
class _AccountFooter extends StatelessWidget {
  const _AccountFooter();

  /// "Pearl Batumbakal" -> "PB"; nothing usable -> "?".
  static String initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final user = SessionController.instance.user;
        final name = (user?.fullName?.trim().isNotEmpty ?? false)
            ? user!.fullName!.trim()
            : (user?.email ?? 'Signed in');
        final role = user?.role == UserRole.owner
            ? 'Owner account'
            : 'Staff account';
        return Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.sidebarBorder)),
          ),
          child: Row(
            children: [
              // The initials repeat the name, so screen readers skip them.
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.avatarGrey,
                  child: Text(
                    initials(user?.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onMaroon,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      role,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.onMaroonMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
