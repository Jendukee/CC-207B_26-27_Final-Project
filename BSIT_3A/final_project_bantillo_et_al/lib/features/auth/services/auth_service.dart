// Email/password authentication against Supabase Auth.
//
// - signIn: signs in, then reloads the role from `profiles` through
//   SessionController so the router knows where to send the user.
// - register: creates the account. full_name, phone and the privacy
//   consent time are sent as user metadata; the database trigger
//   handle_new_user() copies them into `profiles` (role is always
//   'customer' there; staff are promoted by the owner in SQL).
//
// OWNER: team lead.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// Result of [AuthService.register].
enum RegisterResult {
  /// Account created and the user is signed in.
  signedIn,

  /// Account created, but Supabase requires email confirmation first.
  needsEmailConfirmation,
}

/// Sign in and registration.
class AuthService {
  /// Uses the shared Supabase client unless a [client] is given (tests).
  AuthService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  /// Signs in with email + password and returns the user with their role.
  /// Throws [AuthException] on wrong credentials.
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await SessionController.instance.reload();
    return SessionController.instance.user;
  }

  /// Creates a customer account. [privacyConsent] must be true: the form
  /// blocks submission without it, and this method double-checks.
  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
    required bool privacyConsent,
    String? phone,
  }) async {
    if (!privacyConsent) {
      throw ArgumentError('Privacy consent is required to register.');
    }
    final cleanedPhone = phone?.replaceAll(RegExp(r'[\s-]'), '');
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (cleanedPhone != null && cleanedPhone.isNotEmpty)
          'phone': cleanedPhone,
        'privacy_consent_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    if (response.session == null) return RegisterResult.needsEmailConfirmation;
    await SessionController.instance.reload();
    return RegisterResult.signedIn;
  }

  /// Turns any auth error into a message that is safe to show users.
  static String friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login')) {
        return 'Incorrect email or password.';
      }
      if (message.contains('already registered')) {
        return 'An account with this email already exists. Try signing in.';
      }
      if (message.contains('email not confirmed')) {
        return 'Please confirm your email first, then sign in.';
      }
      return error.message;
    }
    return 'Could not reach the server. Check your connection and try again.';
  }
}
