// Customer profile, measurements, privacy consent and deletion requests.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/features/profile/models/data_deletion_request.dart';
import 'package:orange150_rental/features/profile/models/profile_data.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/customer_booking_tab.dart';

/// Reads and updates the signed-in customer's own profile data.
class ProfileService {
  ProfileService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  /// Profile contact and consent fields with saved measurements, if any.
  Future<ProfileData> getProfileData() async {
    final user = _requireUser();
    final profile = await _client
        .from('profiles')
        .select('id, full_name, phone, privacy_consent_at')
        .eq('id', user.id)
        .single();
    final measurements = await _client
        .from('measurements')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return ProfileData.fromRows(
      id: user.id,
      email: user.email,
      profile: profile,
      measurements: measurements,
    );
  }

  /// How many of the customer's bookings are in each My Bookings tab, for
  /// the shortcut icons on the Me page (customer redesign). RLS returns
  /// only the customer's own bookings.
  Future<Map<CustomerBookingTab, int>> bookingCounts() async {
    _requireUser();
    final rows = await _client.from('bookings').select();
    return CustomerBookingTab.countAll(rows.map(Booking.fromMap));
  }

  /// Updates full name and phone in profiles.
  Future<void> updateContact({required String fullName, String? phone}) async {
    final user = _requireUser();
    final cleanedPhone = phone?.trim();
    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': cleanedPhone == null || cleanedPhone.isEmpty
              ? null
              : cleanedPhone,
        })
        .eq('id', user.id)
        .select('id')
        .single();
  }

  /// Updates or withdraws the customer's account privacy consent.
  Future<void> updatePrivacyConsent({required bool consented}) async {
    final user = _requireUser();
    await _client
        .from('profiles')
        .update({
          'privacy_consent_at': consented
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', user.id)
        .select('id')
        .single();
  }

  /// Inserts or updates measurements (upsert on user_id).
  Future<void> saveMeasurements(ProfileMeasurements measurements) async {
    final user = _requireUser();
    await _client.from('measurements').upsert({
      'user_id': user.id,
      ...measurements.toMap(),
      'consent_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// The customer's current open deletion request, or null if none exists.
  Future<DataDeletionRequest?> getOpenDeletionRequest() async {
    final user = _requireUser();
    final row = await _client
        .from('data_deletion_requests')
        .select()
        .eq('user_id', user.id)
        .inFilter('status', ['pending', 'in_review'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DataDeletionRequest.fromMap(row);
  }

  /// Records a request for staff to review account-data deletion.
  Future<DataDeletionRequest> requestDataDeletion({String? reason}) async {
    final user = _requireUser();
    final cleanedReason = reason?.trim();
    final row = await _client
        .from('data_deletion_requests')
        .insert({
          'user_id': user.id,
          if (cleanedReason != null && cleanedReason.isNotEmpty)
            'reason': cleanedReason,
        })
        .select()
        .single();
    return DataDeletionRequest.fromMap(row);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to view or update your profile.');
    }
    return user;
  }
}
