// The shop's editable settings: one row of the shop_settings table
// (0016_shop_settings.sql), changed by the owner in More -> Shop settings.
//
// [ShopSettings.defaults] holds the values the app used before the table
// existed (shop_contact.dart, rental_terms.dart). They are shown whenever
// the table cannot be read (offline, migration not run yet), so customers
// always see a GCash number and contact numbers.
//
// The shop NAME is not a setting: it stays ShopContact.name.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_contact.dart';

/// The shop's settings.
class ShopSettings {
  /// Creates settings.
  const ShopSettings({
    required this.paymentWindowHours,
    required this.lateFeePerDay,
    required this.address,
    required this.contactNumbers,
    required this.gcashNumber,
    this.shopHours,
    this.updatedAt,
    this.updatedBy,
  });

  /// The built-in values (before any edit, and when loading fails).
  static const ShopSettings defaults = ShopSettings(
    paymentWindowHours: 48,
    lateFeePerDay: RentalTerms.lateFeePerDay,
    address: ShopContact.address,
    contactNumbers: ShopContact.phones,
    gcashNumber: ShopContact.gcash,
  );

  /// Builds settings from a shop_settings row. Missing or blank values fall
  /// back to [defaults], so a half-filled row never shows empty numbers.
  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    String? text(Object? value) {
      final t = (value as String?)?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final numbers = [
      for (final n in (map['contact_numbers'] as List?) ?? const [])
        if (text(n) != null) text(n)!,
    ];
    final updatedAt = map['updated_at'] as String?;
    return ShopSettings(
      shopHours: text(map['shop_hours']),
      paymentWindowHours:
          (map['payment_window_hours'] as num?)?.toInt() ??
          defaults.paymentWindowHours,
      lateFeePerDay:
          (map['late_fee_per_day'] as num?)?.toDouble() ??
          defaults.lateFeePerDay,
      address: text(map['address']) ?? defaults.address,
      contactNumbers: numbers.isEmpty ? defaults.contactNumbers : numbers,
      gcashNumber: text(map['gcash_number']) ?? defaults.gcashNumber,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      updatedBy: map['updated_by'] as String?,
    );
  }

  /// e.g. "Mon to Sat, 9:00 AM to 6:00 PM"; null when not set.
  final String? shopHours;

  /// How long an unpaid request stays open (1 to 168 hours).
  final int paymentWindowHours;

  /// Late return fee per extra day, in pesos.
  final double lateFeePerDay;

  /// Shop address.
  final String address;

  /// 1 to 3 contact numbers, main number first.
  final List<String> contactNumbers;

  /// GCash number customers pay to.
  final String gcashNumber;

  /// When the owner last saved (null = never).
  final DateTime? updatedAt;

  /// Who last saved (auth user id).
  final String? updatedBy;

  /// Main number (Call button).
  String get mainNumber => contactNumbers.first;
}
