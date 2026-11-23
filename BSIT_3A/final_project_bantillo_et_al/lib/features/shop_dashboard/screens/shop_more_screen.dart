// "More" tab of the staff shell: links to Reports, Settings and Staff
// accounts, plus Sign out. Reports and Sign out are wired by the skeleton;
// Settings and Staff are still TODO.
//
// OWNER: Member 3. Skeleton placeholder: build out Settings / Staff and
// keep this header comment up to date.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';

/// Placeholder for the "More" screen.
class ShopMoreScreen extends StatelessWidget {
  /// Creates the More screen.
  const ShopMoreScreen({super.key});

  /// Shows a "not built yet" message for TODO links.
  void _todo(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('TODO: Member 3 builds $what')),
    );
  }

  /// Leaves the staff area first, then signs out.
  Future<void> _signOut(BuildContext context) async {
    context.go(RoutePaths.browse);
    await SessionController.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(RouteNames.reports),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Shop settings'),
            subtitle: const Text('TODO: Member 3 builds this'),
            onTap: () => _todo(context, 'Shop settings'),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Staff accounts'),
            subtitle: const Text('TODO: Member 3 builds this'),
            onTap: () => _todo(context, 'Staff accounts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            subtitle: Text(user?.email ?? ''),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
