// The signed-in user plus their role, built from auth.users + profiles.
// Shared by auth, profile, the router guard and staff features.
//
// OWNER: team lead. Change only via a reviewed PR.

/// Roles stored in profiles.role. The database default is customer.
enum UserRole {
  /// A shop customer who books rentals.
  customer,

  /// Shop staff: manages bookings, payments, checklists, inventory.
  staff,

  /// Shop owner: everything staff can do, plus reports and staff admin.
  owner;

  /// Parses the text stored in the database. Unknown values become customer.
  static UserRole fromDb(String? value) => switch (value) {
        'staff' => UserRole.staff,
        'owner' => UserRole.owner,
        _ => UserRole.customer,
      };

  /// The value stored in profiles.role.
  String get dbValue => name;

  /// True for roles that can open the staff screens.
  bool get isStaff => this == UserRole.staff || this == UserRole.owner;
}

/// A signed-in user. Guests are represented by `null`, not by an AppUser.
class AppUser {
  /// Creates a user.
  const AppUser({
    required this.id,
    required this.role,
    this.email,
    this.fullName,
    this.phone,
  });

  /// Builds a user from a `profiles` row. If [profile] is null (row missing
  /// or unreadable) the user falls back to the customer role.
  factory AppUser.fromProfile(
    Map<String, dynamic>? profile, {
    required String id,
    String? email,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: profile?['full_name'] as String?,
      phone: profile?['phone'] as String?,
      role: UserRole.fromDb(profile?['role'] as String?),
    );
  }

  /// Same as auth.users.id and profiles.id.
  final String id;

  /// Login email.
  final String? email;

  /// Display name from profiles.full_name.
  final String? fullName;

  /// Contact number from profiles.phone.
  final String? phone;

  /// Role from profiles.role.
  final UserRole role;
}
