// A payment recorded by staff against a booking (`payments` table).
// Shared by shop_bookings (record payment), my_bookings and reports.
//
// OWNER: team lead. Change only via a reviewed PR.

/// payments.kind
enum PaymentKind {
  /// Paid the full amount at once.
  full('full', 'Full payment'),

  /// 50% down payment.
  down('down', 'Down payment'),

  /// Remaining balance (usually at pickup).
  balance('balance', 'Balance');

  const PaymentKind(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;

  /// Parses the database value.
  static PaymentKind fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => full);
}

/// One payment.
class Payment {
  /// Creates a payment.
  const Payment({
    required this.bookingId,
    required this.amount,
    required this.kind,
    required this.method,
    this.id,
    this.recordedBy,
    this.createdAt,
  });

  /// Builds a payment from a Supabase row.
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String?,
      bookingId: map['booking_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      kind: PaymentKind.fromDb(map['kind'] as String),
      method: map['method'] as String,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }

  /// Primary key; null before the row is inserted.
  final String? id;

  /// The booking this payment belongs to.
  final String bookingId;

  /// Amount in pesos.
  final double amount;

  /// Full, down or balance.
  final PaymentKind kind;

  /// How it was paid, e.g. "cash", "gcash", "bank".
  final String method;

  /// profiles.id of the staff member who recorded it.
  final String? recordedBy;

  /// When it was recorded.
  final DateTime? createdAt;

  /// Row for insert. `recorded_by` defaults to auth.uid() in the database.
  Map<String, dynamic> toInsertMap() => {
        'booking_id': bookingId,
        'amount': amount,
        'kind': kind.dbValue,
        'method': method,
      };
}
