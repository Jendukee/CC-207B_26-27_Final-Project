// Profile tab.
// - Guests: a sign-in prompt (Sign in / Create account) plus the
//   "Staff sign in" link, which is the staff entry point into the app.
//   (Wired by the skeleton; keep it when you build this screen.)
// - Signed-in customers: will show contact details, saved measurements
//   (inches), privacy consent, a data deletion request, and Sign out.
//
// OWNER: Member 2. Skeleton placeholder: replace the signed-in body with
// your own implementation and keep this header comment up to date.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/widgets/sign_in_prompt.dart';

/// Placeholder for the "Profile" screen.
class ProfileScreen extends StatelessWidget {
  /// Creates the profile screen.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (!session.isSignedIn) {
            return const SignInPrompt(
              message: 'Sign in to see your measurements, contact details '
                  'and privacy settings.',
              from: RoutePaths.profile,
              showStaffLink: true,
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TODO: Member 2 builds this',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signed in as ${session.user?.email ?? 'customer'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: session.signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
