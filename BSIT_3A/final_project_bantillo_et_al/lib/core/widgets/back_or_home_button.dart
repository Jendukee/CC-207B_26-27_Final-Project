// A back arrow that always works (customer redesign 2, Phase 1). Used on
// Sign in and Register, which can be opened in two ways:
//
//   * from another screen (e.g. a guest tapped Reserve Now or a heart):
//     Back goes to that screen, and the action is NOT completed;
//   * directly (a link, or after the auth guard replaced the page): there
//     is no previous screen, so Back goes to [fallback] (Browse).
//
// H3 user control and freedom: there is always a way out.
//
// Example:
//   appBar: BrandAppBar(title: 'Sign in', leading: const BackOrHomeButton())
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';

/// Back arrow: previous screen if any, else [fallback].
class BackOrHomeButton extends StatelessWidget {
  /// Creates the button.
  const BackOrHomeButton({super.key, this.fallback = RoutePaths.browse});

  /// Where to go when there is no previous screen.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    // BackButton: the platform's arrow, 48 px, tooltip "Back".
    return BackButton(onPressed: () => goBackOr(context, fallback));
  }
}

/// Goes back one screen, or to [fallback] when there is none.
void goBackOr(BuildContext context, String fallback) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}
