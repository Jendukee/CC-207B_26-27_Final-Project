// Turns any error (Supabase, network, Dart) into a short message users can
// read, so screens never show raw exceptions or Postgres text (UI audit,
// heuristic H9).
//
//   * Our own SQL errors (RAISE EXCEPTION, code P0001) are already written
//     for users, so their message is shown as-is.
//   * "permission denied" / not signed in / no internet get plain wording.
//   * Anything else becomes [fallback].
//
// Example:
//   } catch (error) {
//     showSnack(friendlyErrorMessage(error,
//         fallback: 'Could not save your measurements. Please try again.'));
//   }
//
// OWNER: team lead. Change only via a reviewed PR.

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A friendly message for [error].
String friendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is PostgrestException) {
    final (code, message) = _unwrap(error);
    if (code == 'P0001') return message; // our own SQL messages
    if (code == '42501' || code == '403') {
      return 'You do not have permission to do this. '
          'Try signing out and in again.';
    }
    if (code == 'PGRST116') return 'This record could not be found.';
    return fallback;
  }
  if (error is AuthException) return 'Please sign in again to continue.';

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('XMLHttpRequest')) {
    return 'No internet connection. Check your connection and try again.';
  }
  return fallback;
}

/// The Postgres error code and message. Sometimes (seen on web) the client
/// puts the raw JSON body in `message` and the HTTP status in `code`; then
/// the real values are read from the JSON.
(String, String) _unwrap(PostgrestException error) {
  final raw = error.message.trim();
  if (raw.startsWith('{')) {
    try {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      return (
        body['code']?.toString() ?? error.code ?? '',
        body['message']?.toString() ?? raw,
      );
    } catch (_) {
      // Not JSON after all; fall through.
    }
  }
  return (error.code ?? '', error.message);
}
