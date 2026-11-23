// Thin wrapper around the Supabase client so every feature gets it the
// same way. Features call SupabaseService.client inside their own
// services/ classes; screens should not talk to Supabase directly.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/config/env.dart';

/// Static access point for the shared [SupabaseClient].
abstract final class SupabaseService {
  /// Connects to Supabase using the values from env.json.
  /// Called once from main() before runApp.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // The anon key is Supabase's public client key (passed as publishableKey
      // because `anonKey` is deprecated in supabase_flutter 2.18+).
      publishableKey: Env.supabaseAnonKey,
    );
  }

  /// The shared client (database, storage, functions, auth).
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for the auth client.
  static GoTrueClient get auth => client.auth;
}
