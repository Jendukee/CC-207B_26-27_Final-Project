// Customer profile data: contact details, measurements, privacy consent
// and data deletion requests. Tables: profiles, measurements.
//
// OWNER: Member 2. Every method is a stub that throws UnimplementedError
// until Member 2 implements it.

/// Reads and updates the signed-in customer's own profile data.
class ProfileService {
  /// Saved measurements (inches) or null if none yet.
  Future<Map<String, dynamic>?> getMeasurements() =>
      throw UnimplementedError('TODO(Member 2): read measurements');

  /// Inserts or updates measurements (upsert on user_id).
  Future<void> saveMeasurements(Map<String, dynamic> measurements) =>
      throw UnimplementedError('TODO(Member 2): upsert measurements');

  /// Updates full name and phone in profiles.
  Future<void> updateContact({required String fullName, String? phone}) =>
      throw UnimplementedError('TODO(Member 2): update profile');

  /// Records a request to delete the customer's personal data.
  Future<void> requestDataDeletion({String? reason}) =>
      throw UnimplementedError('TODO(Member 2): data deletion request');
}
