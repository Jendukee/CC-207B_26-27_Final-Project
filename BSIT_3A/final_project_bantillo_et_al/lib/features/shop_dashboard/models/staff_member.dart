// Staff accounts (More -> Staff accounts, owner only): one row of
// list_staff() (0017_staff_logins.sql) and the form rules of the "Add staff"
// and "Reset password" sheets. Pure Dart, no Supabase, so it can be unit
// tested. The manage-staff Edge Function checks the same rules again.
//
// OWNER: Member 3.

import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/shared/models/app_user.dart';

/// A staff or owner account.
class StaffMember {
  /// Creates it.
  const StaffMember({
    required this.id,
    required this.role,
    this.fullName,
    this.email,
    this.phone,
    this.isDisabled = false,
    this.createdAt,
  });

  /// Builds it from a list_staff() row.
  factory StaffMember.fromMap(Map<String, dynamic> map) {
    final created = map['created_at'] as String?;
    return StaffMember(
      id: map['id'] as String,
      fullName: _clean(map['full_name']),
      email: _clean(map['email']),
      phone: _clean(map['phone']),
      role: UserRole.fromDb(map['role'] as String?),
      isDisabled: map['is_disabled'] as bool? ?? false,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  /// Trimmed text, or null when missing or blank.
  static String? _clean(Object? value) {
    final text = (value as String?)?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// profiles.id (= auth user id).
  final String id;

  /// profiles.full_name (may be missing).
  final String? fullName;

  /// Login email from auth.users.
  final String? email;

  /// profiles.phone.
  final String? phone;

  /// staff or owner.
  final UserRole role;

  /// True while the login is disabled (banned); history is kept.
  final bool isDisabled;

  /// When the account was made.
  final DateTime? createdAt;

  /// The name to show: full name, else email, else a placeholder.
  String get displayName => fullName ?? email ?? 'Unnamed account';

  /// True for the owner (no actions on this card).
  bool get isOwner => role == UserRole.owner;
}

/// The email field of the "Add staff" sheet.
abstract final class StaffEmail {
  /// Trimmed and lower-cased, as stored by Supabase Auth.
  static String normalize(String value) => value.trim().toLowerCase();

  /// Required and a valid email (the shared Validators.email).
  static String? validate(String? value) => Validators.email(value);
}

/// The staff password rule: at least 8 characters with a letter and a
/// number (at most 72: Supabase Auth ignores the rest).
abstract final class StaffPassword {
  /// Shortest password.
  static const int minLength = 8;

  /// Longest password Supabase Auth uses in full.
  static const int maxLength = 72;

  /// Helper text under the password field.
  static const String helper =
      'At least 8 characters with a letter and a number';

  /// Returns the error text, or null when the password is acceptable.
  static String? validate(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (password.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    if (password.length > maxLength) {
      return 'Use at most $maxLength characters.';
    }
    if (!RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      return 'Use at least one letter and one number.';
    }
    return null;
  }

  /// "Confirm password": required and the same as [password].
  static String? validateConfirm(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Type the password again.';
    if (value != password) return 'The passwords do not match.';
    return null;
  }
}

/// The full name field of the "Add staff" sheet.
abstract final class StaffName {
  /// Longest name (same as profiles / bookings).
  static const int maxLength = 120;

  /// Required, at most [maxLength] characters.
  static String? validate(String? value) {
    final missing = Validators.required(value, fieldName: 'Full name');
    if (missing != null) return missing;
    if (value!.trim().length > maxLength) {
      return 'Keep the name to $maxLength characters or less.';
    }
    return null;
  }

  /// Trimmed, with inner spaces collapsed.
  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
