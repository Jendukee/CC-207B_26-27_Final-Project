// Release and return checklists: inclusions, condition, damage, photos,
// penalties. Tables/buckets: checklists (insert), bookings (status),
// checklist-photos bucket (staff only).
//
// OWNER: Member 3. Every method is a stub that throws UnimplementedError
// until Member 3 implements it.

import 'dart:typed_data';

import 'package:orange150_rental/features/checklist/models/checklist_kind.dart';

/// Saves checklists (staff/owner RLS).
class ChecklistService {
  /// Saves a checklist and moves the booking to rented_out (release) or
  /// returned (return).
  Future<void> submitChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required Map<String, bool> inclusionsChecked,
    String? conditionNotes,
    List<String> photoUrls = const [],
    String? damageNotes,
    double penaltyAmount = 0,
  }) =>
      throw UnimplementedError('TODO(Member 3): insert checklist');

  /// Uploads a photo to the private checklist-photos bucket and returns its
  /// storage path.
  Future<String> uploadPhoto({
    required String bookingId,
    required Uint8List bytes,
    required String fileName,
  }) =>
      throw UnimplementedError('TODO(Member 3): upload checklist photo');
}
