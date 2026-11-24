// The rental agreement (e-contract) built from the shop's paper reservation
// form, in plain Dart so it can be unit tested (customer redesign,
// Phase 2).
//
//   * AgreementForm  every value on the form, filled in from the checkout
//                    (profile, item, dates, payment, measurements)
//   * rows()         the form as ordered label / value pairs; shown on the
//                    checkout and saved in bookings.terms_snapshot, so the
//                    customer and staff later see exactly what was signed
//   * AgreementRules the signature check (typed name must match the full
//                    name, ignoring case and extra spaces) and which
//                    accessory size fields apply
//
// Left out on purpose (not for customers in the app): "Assisted by",
// "Petticoat", empty accessory checkboxes and the paper signature line.
//
// OWNER: Member 2.

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

/// Signature and accessory rules.
abstract final class AgreementRules {
  /// Error when the typed name does not match.
  static const String nameMismatch =
      'Type your full name exactly as entered above.';

  /// Note shown under the accessories list.
  static const String accessoriesNote =
      'Accessories are free and come with the item. Damaged accessories '
      'will be charged.';

  /// Lowercase with single spaces, e.g. "  Ana   CRUZ " -> "ana cruz".
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// True when [typed] is [fullName] (ignoring case and extra spaces) and
  /// not empty.
  static bool nameMatches(String typed, String fullName) {
    final a = normalizeName(typed);
    return a.isNotEmpty && a == normalizeName(fullName);
  }

  /// Validator for the "Type your full name to sign" field.
  static String? validateSignature(String? typed, String fullName) {
    if ((typed ?? '').trim().isEmpty) return 'Type your full name to sign.';
    if (!nameMatches(typed!, fullName)) return nameMismatch;
    return null;
  }

  /// The form asks for a shoe size only if shoes come with the item.
  static bool needsShoeSize(List<String> inclusions) =>
      inclusions.any((i) => i.toLowerCase().contains('shoe'));

  /// ... and a long sleeves size only if long sleeves come with it.
  static bool needsLongSleevesSize(List<String> inclusions) =>
      inclusions.any((i) => i.toLowerCase().contains('sleeve'));
}

/// Every value written on the rental agreement.
class AgreementForm {
  /// Creates the form.
  const AgreementForm({
    required this.fullName,
    required this.phone,
    required this.item,
    required this.eventDate,
    required this.paymentOption,
    required this.method,
    this.address = '',
    this.facebook = '',
    this.fittingDate,
    this.shoeSize = '',
    this.longSleevesSize = '',
    this.waist,
    this.shoulder,
    this.adjustments = '',
    this.note = '',
  });

  final String fullName;
  final String phone;
  final String address;
  final String facebook;
  final Item item;
  final DateTime eventDate;
  final DateTime? fittingDate;
  final PaymentOption paymentOption;
  final PlannedPaymentMethod method;
  final String shoeSize;
  final String longSleevesSize;
  final double? waist;
  final double? shoulder;

  /// Fitting / adjustment notes from the measurements card.
  final String adjustments;
  final String note;

  DateTime get pickupDate => eventDate.subtract(const Duration(days: 1));
  DateTime get returnDate => eventDate.add(const Duration(days: 1));
  double get dueNow => PaymentPlan.dueNow(item.price, paymentOption);
  double get balance => PaymentPlan.balanceAfter(item.price, paymentOption);

  static String _orDash(String value) =>
      value.trim().isEmpty ? '—' : value.trim();

  static String _inches(double? value) => value == null
      ? '—'
      : '${value == value.roundToDouble() ? value.toInt() : value} in';

  /// "Down payment" line: "50% reservation fee: ₱1,750.00 via GCash".
  String get downPaymentText {
    final kind = paymentOption == PaymentOption.half
        ? '50% reservation fee'
        : 'Full payment';
    return '$kind: ${Formatters.peso(dueNow)} via ${method.label}';
  }

  /// The form as ordered label / value pairs. Optional size rows appear
  /// only when they apply (see [AgreementRules]).
  List<(String, String)> rows() => [
    ('Full name', _orDash(fullName)),
    ('Facebook account', _orDash(facebook)),
    ('Address', _orDash(address)),
    ('Contact number', _orDash(phone)),
    ('Item', '${item.type.label}: ${item.name} (size ${item.size})'),
    (
      'Fitting date',
      fittingDate == null
          ? 'To be arranged with the shop'
          : Formatters.date(fittingDate!),
    ),
    ('Pick-up date', Formatters.date(pickupDate)),
    ('Event date', Formatters.date(eventDate)),
    ('Return date', Formatters.date(returnDate)),
    ('Down payment', downPaymentText),
    ('Balance', Formatters.peso(balance)),
    if (AgreementRules.needsShoeSize(item.inclusions))
      ('Shoes size', _orDash(shoeSize)),
    if (AgreementRules.needsLongSleevesSize(item.inclusions))
      ('Long sleeves size', _orDash(longSleevesSize)),
    ('Waist', _inches(waist)),
    ('Shoulder', _inches(shoulder)),
    ('Adjustments', _orDash(adjustments)),
    ('Note', _orDash(note)),
  ];

  /// What is saved in bookings.terms_snapshot when the customer signs: the
  /// exact terms, the shop header and the filled-in form.
  Map<String, dynamic> toSnapshot({
    required String signedName,
    required DateTime signedAt,
  }) => {
    'version': RentalTerms.version,
    'signed_name': signedName.trim(),
    'signed_at': signedAt.toUtc().toIso8601String(),
    'shop': {
      'name': ShopContact.name,
      'address': ShopContact.address,
      'phones': ShopContact.phones,
      'gcash': ShopContact.gcash,
    },
    'terms': RentalTerms.items,
    'accessories': item.inclusions,
    'accessories_note': AgreementRules.accessoriesNote,
    'rows': [
      for (final (label, value) in rows()) {'label': label, 'value': value},
    ],
  };
}
