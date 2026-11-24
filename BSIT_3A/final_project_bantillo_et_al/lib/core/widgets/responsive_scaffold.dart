// Navigation frame used by both shells (customer and staff).
// - Width < 600: bottom NavigationBar (phones).
// - Width >= 600: side NavigationRail (tablets and web), so staff screens
//   work well on the shop's tablet and on a laptop browser.
// - With alwaysBottomBar: true (customer shell) the bottom NavigationBar
//   is used at every width.
// - Shop-side redesign (Phase 2): the rail shows the Orange 150 mark at the
//   top (BrandBadge, maroon badge so it is visible on the white rail) (H4).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/widgets/brand_app_bar.dart';

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

    if (!alwaysBottomBar && width >= railBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelect,
                labelType: NavigationRailLabelType.all,
                // The logo at the top of the rail (not a button).
                leading: const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: BrandBadge(),
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
            const VerticalDivider(width: 1),
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
