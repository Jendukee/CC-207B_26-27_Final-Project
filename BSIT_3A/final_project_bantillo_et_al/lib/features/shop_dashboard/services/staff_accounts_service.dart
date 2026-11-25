// Staff accounts (owner only).
//
//   list            list_staff()                (0017_staff_logins.sql)
//   create          manage-staff { action: 'create', ... }
//   disable/enable  manage-staff { action: 'disable' | 'enable', user_id }
//   reset password  manage-staff { action: 'reset_password', ... }
//
// The manage-staff Edge Function (supabase/functions/manage-staff) holds the
// service role key and checks that the caller is the owner; the app only
// sends the signed-in user's token (functions.invoke does that itself).
// Errors become friendly text: the function's own { error } message when it
// sends one, else core's friendlyErrorMessage.
//
// OWNER: Member 3.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';

/// Thrown with a message that is safe to show (e.g. "An account with this
/// email already exists.").
class StaffAccountsException implements Exception {
  /// Creates the exception.
  const StaffAccountsException(this.message);

  /// Friendly text.
  final String message;

  @override
  String toString() => message;
}

/// Calls list_staff() and the manage-staff Edge Function.
class StaffAccountsService {
  /// The Edge Function's name.
  static const String functionName = 'manage-staff';

  /// Staff and owner accounts, owner first.
  Future<List<StaffMember>> listStaff() async {
    try {
      final rows = await SupabaseService.client.rpc('list_staff') as List;
      return [
        for (final row in rows)
          StaffMember.fromMap(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (error) {
      throw StaffAccountsException(
        friendlyErrorMessage(
          error,
          fallback: 'Could not load staff accounts. Please try again.',
        ),
      );
    }
  }

  /// Creates a staff login (already confirmed, role staff).
  Future<void> createStaff({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) => _invoke({
    'action': 'create',
    'full_name': StaffName.normalize(fullName),
    'email': StaffEmail.normalize(email),
    'password': password,
    if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
  }, fallback: 'Could not create the staff account. Please try again.');

  /// Blocks signing in; the profile and booking history stay.
  Future<void> disable(String userId) => _invoke({
    'action': 'disable',
    'user_id': userId,
  }, fallback: 'Could not disable this account. Please try again.');

  /// Allows signing in again.
  Future<void> enable(String userId) => _invoke({
    'action': 'enable',
    'user_id': userId,
  }, fallback: 'Could not enable this account. Please try again.');

  /// Sets a new password for a staff login.
  Future<void> resetPassword(String userId, String newPassword) => _invoke({
    'action': 'reset_password',
    'user_id': userId,
    'new_password': newPassword,
  }, fallback: 'Could not change the password. Please try again.');

  /// Calls manage-staff with [body]; throws [StaffAccountsException].
  Future<void> _invoke(
    Map<String, dynamic> body, {
    required String fallback,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: body,
      );
      final error = errorFrom(response.data);
      if (error != null) throw StaffAccountsException(error);
    } on StaffAccountsException {
      rethrow;
    } on FunctionException catch (e) {
      throw StaffAccountsException(messageFor(e, fallback: fallback));
    } catch (e) {
      throw StaffAccountsException(friendlyErrorMessage(e, fallback: fallback));
    }
  }

  /// The function's { "error": "..." } text, if any.
  static String? errorFrom(Object? data) {
    if (data is Map && data['error'] is String) {
      final text = (data['error'] as String).trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// A friendly message for a failed function call: its own error text,
  /// else a message by HTTP status.
  static String messageFor(
    FunctionException error, {
    required String fallback,
  }) {
    final own = errorFrom(error.details);
    if (own != null) return own;
    return switch (error.status) {
      401 || 403 => 'Only the owner can manage staff accounts.',
      404 =>
        'Staff management is not set up yet. Deploy the manage-staff '
            'function.',
      504 => 'The server took too long. Please try again.',
      _ => fallback,
    };
  }
}
