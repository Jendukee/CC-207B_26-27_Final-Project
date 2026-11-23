// Centered loading spinner with an optional message.
// Use it for any "waiting for Supabase" state so loading looks the same
// everywhere.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

/// A full-area loading indicator.
class LoadingView extends StatelessWidget {
  /// Creates a loading view. [message] is read by screen readers too.
  const LoadingView({super.key, this.message = 'Loading...'});

  /// Text under the spinner.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
