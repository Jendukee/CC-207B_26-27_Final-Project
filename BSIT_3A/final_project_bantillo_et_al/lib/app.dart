// Root widget of the app: MaterialApp.router with the Orange 150 theme
// and the go_router configuration from core/router/app_router.dart.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/router/app_router.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/core/widgets/app_messenger.dart';

/// The top-level app widget. Holds no state; routing and session state
/// live in [AppRouter] and SessionController.
class Orange150App extends StatelessWidget {
  /// Creates the root app widget.
  const Orange150App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Orange 150 Rentals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // One app-wide messenger, so a snackbar can be shown from a route
      // redirect (e.g. "Saved to favorites" after signing in). H1.
      scaffoldMessengerKey: AppMessenger.key,
      routerConfig: AppRouter.router,
    );
  }
}
