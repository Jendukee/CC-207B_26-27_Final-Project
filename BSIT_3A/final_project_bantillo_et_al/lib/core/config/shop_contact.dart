// The shop's details, in ONE place, copied exactly from the shop's paper
// reservation form. Every screen reads them from here: the Contact the shop
// dialog, the request-submitted screen (GCash number to pay to), payment
// instructions and the e-contract header.
//
// OWNER: team lead. Change only via a reviewed PR.

/// Orange 150 contact and payment information.
abstract final class ShopContact {
  /// Shop name as printed on the form.
  static const String name = 'Orange 150 Gowns & Suits Rental';

  /// Short name for running text ("Call Orange 150 ...").
  static const String shortName = 'Orange 150';

  /// Shop address as printed on the form.
  static const String address =
      'Blk. 39 Lot 20 Bolilao, Mandurriao (across SM City Iloilo)';

  /// Contact numbers, main number first.
  static const List<String> phones = ['09157352844', '09544231197'];

  /// Main number (used for the Call button).
  static const String phone = '09157352844';

  /// GCash number customers send payments to.
  static const String gcash = '09157352844';

  /// "09157352844 / 09544231197", as printed on the form.
  static String get phonesText => phones.join(' / ');
}
