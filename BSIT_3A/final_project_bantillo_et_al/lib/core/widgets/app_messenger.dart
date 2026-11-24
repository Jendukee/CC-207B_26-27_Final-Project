// One app-wide ScaffoldMessenger (customer redesign 2, Phase 1), so code that
// runs outside a screen can still show a snackbar. Used when a favorite is
// saved right after signing in (the save happens in a route redirect, where
// there is no BuildContext for a screen).
//
// app.dart passes [AppMessenger.key] to MaterialApp.router. Screens keep
// using ScaffoldMessenger.of(context) as before; both reach the same one.
//
// H1 visibility of system status: the user is told the item was saved.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// The app's root ScaffoldMessenger.
abstract final class AppMessenger {
  /// Given to MaterialApp.router (scaffoldMessengerKey).
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'appMessenger');

  /// Shows a short [message]; does nothing before the app is built.
  static void show(String message) {
    key.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
