// "More" tab of the staff shell:
//   * who is signed in (name, email, role)
//   * Reports
//   * Shop settings and Staff accounts (placeholder pages for now)
//   * Sign out, through the existing SessionController (not modified)
//
// Shop-side redesign (Phase 2): laid out like the customer "Me" page, on a
// light grey page with white cards: the account card, then a card of list
// tiles (maroon icons, a subtitle, a chevron), then Sign out in red in its
// own card, still asking first (H3, H4, H5). Navigation is unchanged.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/features/shop_dashboard/shop_dashboard_routes.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// The staff "More" screen.
class ShopMoreScreen extends StatelessWidget {
  /// Creates the More screen.
  const ShopMoreScreen({super.key});

  /// Asks for confirmation, signs out, then shows Browse. Sign out FIRST:
  /// while still signed in as staff, the auth guard sends any customer page
  /// back to the Dashboard.
  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to use the '
          'staff screens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          // Red, like the customer Sign out (H4).
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Grab the router now; this screen is gone after signing out.
    final router = GoRouter.of(context);
    await SessionController.instance.signOut();
    router.go(RoutePaths.browse);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SessionController.instance.user;
    final name = (user?.fullName ?? '').trim();
    final role = user?.role == UserRole.owner ? 'Owner' : 'Staff';
    const gap = EdgeInsets.fromLTRB(8, 0, 8, 8);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: const BrandAppBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          // Who is signed in.
          SectionCard(
            margin: gap,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.maroon,
                  foregroundColor: AppColors.onMaroon,
                  child: Icon(Icons.person_outline, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Signed in' : name,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(role, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Shop tools, as list tiles.
          SectionCard(
            margin: gap,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  Icons.bar_chart,
                  'Reports',
                  'Rentals, top items and revenue',
                  () => context.goNamed(RouteNames.reports),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.settings_outlined,
                  'Shop settings',
                  'Coming soon',
                  () => context.goNamed(ShopMoreRoutes.settingsName),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.badge_outlined,
                  'Staff accounts',
                  'Coming soon',
                  () => context.goNamed(ShopMoreRoutes.staffName),
                ),
              ],
            ),
          ),

          // Sign out: red, in its own card, asks first (H5).
          SectionCard(
            margin: gap,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.deepRed),
              title: const Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.deepRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }

  /// A list tile like the customer Me page.
  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: AppColors.maroon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
