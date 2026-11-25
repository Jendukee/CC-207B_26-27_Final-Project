// Navigation frame used by both shells (customer and staff).
// - Width < 600: bottom NavigationBar (phones).
// - Width >= 600: side NavigationRail (tablets and web), so staff screens
//   work well on the shop's tablet and on a laptop browser.
// - With alwaysBottomBar: true (customer shell) the bottom NavigationBar
//   is used at every width.
// - Shop-side redesign (Phase 2): the rail shows the Orange 150 mark at the
//   top (H4).
// - Staff dashboard design: from 1000 px the staff shell shows the dark
//   maroon BrandSidebar (logo, labelled items, signed-in account) instead
//   of the rail; from 600 to 1000 px the rail uses the same dark maroon
//   colors and the white logo tile. Same branches, same taps (H4).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/brand_sidebar.dart';

/// One tab in the navigation bar / rail.
class ResponsiveDestination {
  /// Creates a destination.
  const ResponsiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Icon when not selected.
  final IconData icon;

  /// Icon when selected.
  final IconData selectedIcon;

  /// Tab label (always visible, not icon-only).
  final String label;
}

/// Wraps a go_router [StatefulNavigationShell] with adaptive navigation.
class ResponsiveScaffold extends StatelessWidget {
  /// Creates the scaffold. [destinations] must match the shell's branches
  /// in the same order.
  const ResponsiveScaffold({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.alwaysBottomBar = false,
  });

  /// When true, never switch to the NavigationRail (customer shell).
  final bool alwaysBottomBar;

  /// Width at which we switch from bottom bar to rail.
  static const double railBreakpoint = 600;

  /// Width from which the full BrandSidebar replaces the rail.
  static const double sidebarBreakpoint = 1000;

  /// The shell provided by StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  /// Tabs, in branch order.
  final List<ResponsiveDestination> destinations;

  /// Switches branch. Tapping the current tab again pops it to its root.
  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (!alwaysBottomBar && width >= sidebarBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            BrandSidebar(
              items: [
                for (final d in destinations)
                  (icon: d.icon, selectedIcon: d.selectedIcon, label: d.label),
              ],
              selectedIndex: navigationShell.currentIndex,
              onSelect: _onSelect,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    if (!alwaysBottomBar && width >= railBreakpoint) {
      const muted = AppColors.onMaroonMuted;
      return Scaffold(
        body: Row(
          children: [
            // Dark maroon behind the status bar too.
            ColoredBox(
              color: AppColors.maroonDeep,
              child: SafeArea(
                child: NavigationRail(
                  backgroundColor: AppColors.maroonDeep,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onSelect,
                  labelType: NavigationRailLabelType.all,
                  // White pill behind the selected icon, as in the sidebar.
                  indicatorColor: Colors.white,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.maroonDeep,
                  ),
                  unselectedIconTheme: const IconThemeData(color: muted),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.onMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelTextStyle: const TextStyle(color: muted),
                  // The logo at the top of the rail (not a button).
                  leading: const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: BrandLogoTile(size: 44, semanticLabel: 'Orange 150'),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
