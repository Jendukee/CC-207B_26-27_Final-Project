// Release and return checklists.
//
// * loadBooking: bookings + customer name + items with their inclusions
//   (SELECT grants come from 0006_table_grants.sql).
// * uploadPhoto: private checklist-photos bucket at
//   <booking_id>/<kind>/<timestamp>.jpg (staff-only policies in 0001).
// * saveChecklist: the save_checklist SQL function (0003), which saves the
//   checklist AND changes the status in one transaction:
//     release -> rented_out (balance must be paid)
//     return  -> returned   (items -> cleaning_repair)
//
// OWNER: Member 3.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:orange150_rental/features/checklist/models/checklist_booking.dart';
import 'package:orange150_rental/features/checklist/models/checklist_kind.dart';
import 'package:orange150_rental/shared/models/booking.dart';

/// Thrown by [ChecklistService] with a message that is safe to show.
class ChecklistException implements Exception {
  /// Creates the exception.
  const ChecklistException(this.message);

  /// Friendly text for the screen.
  final String message;

  @override
  String toString() => message;
}

/// Checklist operations (staff/owner RLS).
class ChecklistService {
  /// Private bucket created in 0001.
  static const String photoBucket = 'checklist-photos';

  SupabaseClient get _db => SupabaseService.client;

  /// The booking with customer name and items (with inclusions).
  Future<ChecklistBooking> loadBooking(String bookingId) async {
    try {
      final row = await _db
          .from('bookings')
          .select(
            '*, '
            'customer:profiles!bookings_customer_id_fkey(full_name), '
            'booking_items(item:items(id, name, size, inclusions))',
          )
          .eq('id', bookingId)
          .single();
      return ChecklistBooking.fromMap(row);
    } catch (error) {
      throw ChecklistException(friendlyError(error));
    }
  }

  /// Uploads one photo and returns its storage path,
  /// e.g. "(booking id)/release/1767000000000.jpg".
  ///
  /// The path always ends in .jpg as agreed; the real image type is sent
  /// as the content type so browsers still show it correctly.
  Future<String> uploadPhoto({
    required String bookingId,
    required ChecklistKind kind,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = '$bookingId/${kind.dbValue}/$timestamp.jpg';
    try {
      await _db.storage
          .from(photoBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? 'image/jpeg',
              // Never overwrite an existing photo.
              upsert: false,
            ),
          );
      return path;
    } catch (error) {
      throw ChecklistException(friendlyError(error));
    }
  }

  /// Saves the checklist and changes the booking status. Returns the
  /// updated booking.
  Future<Booking> saveChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required Map<String, bool> inclusionsChecked,
    String? conditionNotes,
    List<String> photoPaths = const [],
    String? damageNotes,
    double penaltyAmount = 0,
  }) async {
    try {
      final row = await _db.rpc<Map<String, dynamic>>(
        'save_checklist',
        params: {
          'p_booking_id': bookingId,
          'p_kind': kind.dbValue,
          'p_inclusions_checked': inclusionsChecked,
          'p_condition_notes': conditionNotes,
          'p_photo_paths': photoPaths,
          'p_damage_notes': damageNotes,
          'p_penalty_amount': penaltyAmount,
        },
      );
      return Booking.fromMap(row);
    } catch (error) {
      throw ChecklistException(friendlyError(error));
    }
  }

  /// Turns any error into a message staff can understand.
  static String friendlyError(Object error) {
    debugPrint('ChecklistService error: $error');
    if (error is ChecklistException) return error.message;

    if (error is StorageException) {
      final status = error.statusCode ?? '';
      if (status == '403' || status == '401') {
        return 'Photo upload was blocked. Only staff accounts can upload '
            'checklist photos.';
      }
      if (status == '413') {
        return 'This photo is too large. Try a smaller photo.';
      }
      return 'A photo could not be uploaded. Check your connection and '
          'press Retry.';
    }

    if (error is PostgrestException) {
      final (code, message) = _unwrap(error);
      // Our own RAISE EXCEPTION messages (0002, 0003) are already friendly.
      if (code == 'P0001') return message;
      if (code == 'PGRST116') {
        return 'Booking not found. It may have been deleted.';
      }
      if (code == '42501' || code == '403') {
        if (message.contains('permission denied')) {
          return 'The database blocked this request (missing permission). '
              'Make sure 0006_table_grants.sql and 0003_checklist.sql have '
              'been run in Supabase.';
        }
        return 'Only staff and owner accounts can do this. '
            'Sign in with a staff account.';
      }
      if (code == 'PGRST202') {
        return 'Checklists are not set up in the database yet. '
            'Run 0003_checklist.sql in the Supabase SQL editor.';
      }
      return 'The server could not complete this request. Please try again.';
    }

    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return 'No internet connection. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Returns the Postgres error code and message. Sometimes (seen on web)
  /// the client puts the raw JSON body in `message` and the HTTP status in
  /// `code`; then the real values are read from the JSON.
  static (String, String) _unwrap(PostgrestException error) {
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
}
