// Customer reservation data access: availability, measurements and bookings.

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Creates reservations for the signed-in customer.
class ReservationService {
  ReservationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Loads one catalog item for the reservation flow.
  Future<Item> getItem(String itemId) async {
    final row = await _client.from('items').select().eq('id', itemId).single();
    return Item.fromMap(row);
  }

  /// True if [itemId] is free from the day before to the day after
  /// [eventDate].
  Future<bool> isItemAvailable({
    required String itemId,
    required DateTime eventDate,
  }) async {
    final from = DateTime(eventDate.year, eventDate.month, eventDate.day - 1);
    final to = DateTime(eventDate.year, eventDate.month, eventDate.day + 1);
    final blockedDates = await _client.rpc(
      'get_blocked_dates',
      params: {
        'p_item_id': itemId,
        'p_from': _dateFormat.format(from),
        'p_to': _dateFormat.format(to),
      },
    ) as List<dynamic>;

    return blockedDates.isEmpty;
  }

  /// The customer's saved measurements (to prefill step 2), or null.
  Future<Map<String, dynamic>?> loadSavedMeasurements() async {
    final userId = _requireUserId();
    final row = await _client
        .from('measurements')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row;
  }

  /// Stores the customer's measurements after they give measurement consent.
  Future<void> saveMeasurements(Map<String, dynamic> measurements) async {
    final userId = _requireUserId();
    await _client.from('measurements').upsert({
      'user_id': userId,
      'chest': measurements['chest'],
      'waist': measurements['waist'],
      'hips': measurements['hips'],
      'shoulder': measurements['shoulder'],
      'height': measurements['height'],
      'inseam': measurements['inseam'],
      'notes': measurements['notes'],
      'consent_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Earliest event date a customer can choose: 2 days from today, so the
  /// pick-up (day before) is tomorrow or later and the 48-hour payment
  /// deadline ends before pick-up day (see 0009_create_reservation.sql).
  static DateTime earliestEventDate([DateTime? now]) {
    final base = now ?? DateTime.now();
    return DateTime(base.year, base.month, base.day + 2);
  }

  /// Creates a pending booking with its item and returns it.
  ///
  /// UI audit #8: everything happens in ONE database function,
  /// create_reservation (0009_create_reservation.sql). It takes the price
  /// from the items table, checks the dates are still free, sets the
  /// payment deadline (expires_at) and inserts the booking and its item
  /// together, so a half-saved booking can no longer be left behind.
  Future<Booking> submitReservation({
    required String itemId,
    required DateTime eventDate,
    required PaymentOption paymentOption,
    required Map<String, dynamic> measurementsSnapshot,
    required String termsVersion,
  }) async {
    _requireUserId();
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_reservation',
      params: {
        'p_item_id': itemId,
        'p_event_date': _dateFormat.format(eventDate),
        'p_payment_option': paymentOption.dbValue,
        'p_measurements': measurementsSnapshot,
        'p_terms_version': termsVersion,
      },
    );
    return Booking.fromMap(row);
  }

  /// Loads a booking for the confirmation screen.
  Future<Booking> getBooking(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .single();
    return Booking.fromMap(row);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in to continue with a reservation.');
    }
    return userId;
  }
}
