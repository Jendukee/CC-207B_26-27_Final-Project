// A staff login disabled by the owner (manage-staff bans it in Supabase
// Auth) must show "This account has been disabled. Contact the shop owner."
// instead of the raw "User is banned" error. Other sign-in errors keep
// their wording.
// Run with: flutter test test/features/auth

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/features/auth/services/auth_service.dart';

void main() {
  test('banned (by code) shows the disabled message', () {
    expect(
      AuthService.friendlyError(
        const AuthException(
          'User is banned',
          statusCode: '400',
          code: 'user_banned',
        ),
      ),
      AuthService.disabledAccountMessage,
    );
  });

  test('banned (message only, older servers) shows the disabled message', () {
    expect(
      AuthService.friendlyError(const AuthException('User is banned')),
      'This account has been disabled. Contact the shop owner.',
    );
  });

  test('other errors are unchanged', () {
    expect(
      AuthService.friendlyError(
        const AuthException('Invalid login credentials'),
      ),
      'Incorrect email or password.',
    );
    expect(
      AuthService.friendlyError(const AuthException('Email not confirmed')),
      'Please confirm your email first, then sign in.',
    );
  });
}
