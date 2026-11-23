// Entry point of the Orange 150 rental app.
//
// 1. Checks that env.json was passed with --dart-define-from-file=env.json.
//    If not, shows a setup error screen instead of crashing.
// 2. Initializes Supabase with the URL and anon key from Env.
// 3. Starts the SessionController (restores the saved session and role)
//    and runs the app. The Splash screen waits for the session to load.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:orange150_rental/app.dart';
import 'package:orange150_rental/core/config/env.dart';
import 'package:orange150_rental/core/config/missing_env_app.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';

/// Boots the app: validates config, connects Supabase, then calls runApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stop early with a readable message if env.json is missing or incomplete.
  if (!Env.isConfigured) {
    runApp(MissingEnvApp(missingKeys: Env.missingKeys));
    return;
  }

  try {
    await SupabaseService.initialize();
  } catch (error) {
    runApp(
      MissingEnvApp(
        missingKeys: const [],
        detail: 'Supabase could not start. Check SUPABASE_URL and '
            'SUPABASE_ANON_KEY in env.json.\n\n$error',
      ),
    );
    return;
  }

  // Load the saved session + role in the background; Splash shows meanwhile.
  unawaited(SessionController.instance.start());

  runApp(const Orange150App());
}
