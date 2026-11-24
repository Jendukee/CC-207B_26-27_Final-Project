// Customer reservation data access for the checkout: item, availability,
// contact details (incl. the optional profile address), measurements and
// creating the booking with its signed e-contract.
//
// Writes:
//   * profiles: full_name, phone and (only when the customer ticks "Save
//     this address to my profile") address
//   * measurements: upsert, with consent
//   * bookings + booking_items: ONLY through create_reservation (0011)
//
// OWNER: Member 2.

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/utils/event_date_rules.dart';
import 'package:orange150_rental/features/reservation/models/payment_plan.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// The customer's saved contact details.
typedef CheckoutContact = ({String fullName, String phone, String address});

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

  /// The signed-in customer's name, mobile and address, to pre-fill the
  /// checkout's Contact details card. Empty strings when not set.
  Future<CheckoutContact> loadContact() async {
    final userId = _requireUserId();
    final row = await _client
        .from('profiles')
        .select('full_name, phone, address')
        .eq('id', userId)
        .maybeSingle();
    String text(String key) => (row?[key] as String? ?? '').trim();
    return (
      fullName: text('full_name'),
      phone: text('phone'),
      address: text('address'),
    );
  }

  /// Saves the name and mobile from the checkout to the customer's profile.
  /// [address] is only written when not null (the customer ticked "Save
  /// this address to my profile").
  Future<void> saveContact({
    required String fullName,
    required String phone,
    String? address,
  }) async {
    final userId = _requireUserId();
    final trimmedAddress = address?.trim();
    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          if (address != null)
            'address': trimmedAddress!.isEmpty ? null : trimmedAddress,
        })
        .eq('id', userId);
  }

  /// The customer's saved measurements (to prefill the checkout), or null.
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

  /// Earliest event date a customer can choose (2 days from today).
  static DateTime earliestEventDate([DateTime? now]) =>
      EventDateRules.earliestEventDate(now);

  /// Creates a pending booking with its item and its signed e-contract.
  ///
  /// Everything happens in ONE database function, create_reservation
  /// (0011_econtract.sql): it takes the price from the items table, checks
  /// the dates, the signature (typed name = profile name) and the terms,
  /// sets the payment deadline and inserts the booking and its item
  /// together.
  Future<Booking> submitReservation({
    required String itemId,
    required DateTime eventDate,
    required PaymentOption paymentOption,
    required Map<String, dynamic> measurementsSnapshot,
    required String termsVersion,
    required String signedName,
    required DateTime termsAcknowledgedAt,
    required Map<String, dynamic> termsSnapshot,
    required PlannedPaymentMethod paymentMethod,
    String? address,
    String? facebook,
    DateTime? fittingDate,
    String? notes,
  }) async {
    _requireUserId();
    String? orNull(String? value) =>
        (value ?? '').trim().isEmpty ? null : value!.trim();
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_reservation',
      params: {
        'p_item_id': itemId,
        'p_event_date': _dateFormat.format(eventDate),
        'p_payment_option': paymentOption.dbValue,
        'p_measurements': measurementsSnapshot,
        'p_terms_version': termsVersion,
        'p_signed_name': signedName.trim(),
        'p_terms_acknowledged_at': termsAcknowledgedAt
            .toUtc()
            .toIso8601String(),
        'p_terms_snapshot': termsSnapshot,
        'p_customer_address': orNull(address),
        'p_facebook_account': orNull(facebook),
        'p_preferred_fitting_date': fittingDate == null
            ? null
            : _dateFormat.format(fittingDate),
        'p_notes': orNull(notes),
        'p_preferred_payment_method': paymentMethod.dbValue,
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
