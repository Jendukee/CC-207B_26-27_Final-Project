// A rental booking (one row of the `bookings` table).
// Shared by reservation, my_bookings, shop_bookings, calendar, checklist,
// dashboard and reports.
//
// Date rule (also a database check): pickup = event - 1 day and
// return = event + 1 day.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:orange150_rental/shared/models/booking_status.dart';

/// bookings.payment_option
enum PaymentOption {
  /// Customer pays the full amount up front.
  full('full', 'Full payment'),

  /// Customer pays 50% now and the balance at pickup.
  half('half', '50% down payment');

  const PaymentOption(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;

  /// Parses the database value.
  static PaymentOption fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => full);
}

/// One booking.
class Booking {
  /// Creates a booking.
  const Booking({
    required this.id,
    required this.referenceNo,
    required this.customerId,
    required this.status,
    required this.paymentOption,
    required this.totalAmount,
    required this.amountPaid,
    required this.pickupDate,
    required this.eventDate,
    required this.returnDate,
    this.measurementsSnapshot,
    this.termsVersion,
    this.termsAcknowledgedAt,
    this.expiresAt,
    this.createdAt,
    this.signedName,
    this.termsSnapshot,
    this.customerAddress,
    this.facebookAccount,
    this.preferredFittingDate,
    this.notes,
    this.preferredPaymentMethod,
  });

  /// Builds a booking from a Supabase row.
  factory Booking.fromMap(Map<String, dynamic> map) {
    DateTime? optionalDate(String key) =>
        map[key] == null ? null : DateTime.parse(map[key] as String);

    return Booking(
      id: map['id'] as String,
      referenceNo: map['reference_no'] as String,
      customerId: map['customer_id'] as String,
      status: BookingStatus.fromDb(map['status'] as String),
      paymentOption: PaymentOption.fromDb(map['payment_option'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num? ?? 0).toDouble(),
      pickupDate: DateTime.parse(map['pickup_date'] as String),
      eventDate: DateTime.parse(map['event_date'] as String),
      returnDate: DateTime.parse(map['return_date'] as String),
      measurementsSnapshot:
          map['measurements_snapshot'] as Map<String, dynamic>?,
      termsVersion: map['terms_version'] as String?,
      termsAcknowledgedAt: optionalDate('terms_acknowledged_at'),
      expiresAt: optionalDate('expires_at'),
      createdAt: optionalDate('created_at'),
      // E-contract columns (migration 0011); null on older bookings.
      signedName: map['signed_name'] as String?,
      termsSnapshot: map['terms_snapshot'] as Map<String, dynamic>?,
      customerAddress: map['customer_address'] as String?,
      facebookAccount: map['facebook_account'] as String?,
      preferredFittingDate: optionalDate('preferred_fitting_date'),
      notes: map['notes'] as String?,
      preferredPaymentMethod: map['preferred_payment_method'] as String?,
    );
  }

  /// Primary key (uuid).
  final String id;

  /// Human-friendly reference shown to customers and staff.
  final String referenceNo;

  /// profiles.id of the customer.
  final String customerId;

  /// Current lifecycle status.
  final BookingStatus status;

  /// Full or 50% down.
  final PaymentOption paymentOption;

  /// Total rental price in pesos.
  final double totalAmount;

  /// Sum of recorded payments in pesos.
  final double amountPaid;

  /// Day before the event.
  final DateTime pickupDate;

  /// The customer's event day.
  final DateTime eventDate;

  /// Day after the event.
  final DateTime returnDate;

  /// Copy of the customer's measurements at booking time.
  final Map<String, dynamic>? measurementsSnapshot;

  /// Version of the e-contract terms the customer accepted.
  final String? termsVersion;

  /// When the customer accepted the terms.
  final DateTime? termsAcknowledgedAt;

  /// When an unpaid pending booking expires.
  final DateTime? expiresAt;

  /// When the booking was created.
  final DateTime? createdAt;

  /// Full name the customer typed to sign the e-contract.
  final String? signedName;

  /// The exact terms and shop details shown when the customer signed:
  /// {"version", "terms": [...], "shop": {...}, "form": {...}}.
  final Map<String, dynamic>? termsSnapshot;

  /// Address given at checkout (optional).
  final String? customerAddress;

  /// Facebook account the shop may use to reach the customer (optional).
  final String? facebookAccount;

  /// Preferred fitting date (optional; arranged with the shop if null).
  final DateTime? preferredFittingDate;

  /// Note from the customer on the form (optional).
  final String? notes;

  /// cash / gcash / bank, chosen at checkout (optional).
  final String? preferredPaymentMethod;

  /// True when the e-contract was signed with a typed name.
  bool get isSigned => (signedName ?? '').trim().isNotEmpty;

  /// Amount still owed in pesos (never negative).
  double get balance =>
      (totalAmount - amountPaid).clamp(0, double.infinity).toDouble();

  /// The status to SHOW (UI audit #14): a pending booking past its payment
  /// deadline ([expiresAt]) is shown as Expired, on the customer and staff
  /// side alike, even though the database row still says pending.
  /// [now] can be fixed in tests.
  BookingStatus displayStatus([DateTime? now]) {
    final deadline = expiresAt;
    final pastDeadline =
        status == BookingStatus.pending &&
        deadline != null &&
        deadline.isBefore(now ?? DateTime.now());
    return pastDeadline ? BookingStatus.expired : status;
  }
}
