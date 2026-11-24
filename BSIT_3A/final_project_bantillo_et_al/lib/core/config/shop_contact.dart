// The shop's contact details, in ONE place (UI audit, finding #9).
// Used by the "Contact the shop" button (core/widgets/contact_shop.dart).
//
// TODO(team lead): replace the placeholder with the real shop mobile
// number (11 digits, 09XXXXXXXXX). Until then the dialog says the number
// is not set and the Call / Copy buttons are disabled.
//
// OWNER: team lead. Change only via a reviewed PR.

/// Orange 150 contact information.
abstract final class ShopContact {
  /// Shop name shown in the dialog.
  static const String name = 'Orange 150';

  /// Shop mobile number, 09XXXXXXXXX. Placeholder until filled in.
  static const String phone = '09XXXXXXXXX';

  /// True once [phone] is a real 11-digit number starting with 09.
  static bool get isPhoneSet => RegExp(r'^09\d{9}$').hasMatch(phone);
}
