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

  /// Creates a pending booking and its booking_items row, then returns it.
  ///
  /// The database trigger derives the item's rental period from the booking.
  Future<Booking> submitReservation({
    required String itemId,
    required DateTime eventDate,
    required PaymentOption paymentOption,
    required Map<String, dynamic> measurementsSnapshot,
    required String termsVersion,
  }) async {
    final userId = _requireUserId();
    final item = await _client
        .from('items')
        .select('price, condition')
        .eq('id', itemId)
        .single();
    if (item['condition'] != 'available') {
      throw StateError('This item is no longer available to rent.');
    }
    final price = (item['price'] as num).toDouble();

    if (!await isItemAvailable(itemId: itemId, eventDate: eventDate)) {
      throw StateError(
        'This item is no longer available for the selected rental dates.',
      );
    }

    final pickupDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day - 1,
    );
    final returnDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day + 1,
    );
    final bookingRow = await _client
        .from('bookings')
        .insert({
          'customer_id': userId,
          'status': 'pending',
          'payment_option': paymentOption.dbValue,
          'total_amount': price,
          'amount_paid': 0,
          'pickup_date': _dateFormat.format(pickupDate),
          'event_date': _dateFormat.format(eventDate),
          'return_date': _dateFormat.format(returnDate),
          'measurements_snapshot': measurementsSnapshot,
          'terms_version': termsVersion,
          'terms_acknowledged_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    await _client.from('booking_items').insert({
      'booking_id': bookingRow['id'],
      'item_id': itemId,
      'price': price,
    });

    return Booking.fromMap(bookingRow);
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
