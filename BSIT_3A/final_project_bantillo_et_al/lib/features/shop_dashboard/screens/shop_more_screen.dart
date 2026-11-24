// "More" tab of the staff shell:
//   * who is signed in (name, email, role)
//   * Reports
//   * Shop settings and Staff accounts (placeholder pages for now)
//   * Sign out, through the existing SessionController (not modified)
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
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
          FilledButton(
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
    final user = SessionController.instance.user;
    final name = (user?.fullName ?? '').trim();
    final role = user?.role == UserRole.owner ? 'Owner' : 'Staff';

    return Scaffold(
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: const BrandAppBar(title: 'More'),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(name.isEmpty ? 'Signed in' : name),
            subtitle: Text(
              [if (user?.email != null) user!.email!, role].join(' · '),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            subtitle: const Text('Rentals, top items and revenue'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(RouteNames.reports),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Shop settings'),
            subtitle: const Text('Coming soon'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(ShopMoreRoutes.settingsName),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Staff accounts'),
            subtitle: const Text('Coming soon'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(ShopMoreRoutes.staffName),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
