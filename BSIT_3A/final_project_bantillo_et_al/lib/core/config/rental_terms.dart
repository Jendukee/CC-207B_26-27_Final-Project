// The shop's rental terms and conditions, copied from the paper
// reservation form (plain sentence case). Shown on the e-contract, on
// Profile -> Rental terms and in booking details, so they are kept in ONE
// place. When the wording changes, bump [version] so each booking records
// which version the customer agreed to (bookings.terms_version).
//
// OWNER: team lead. Change only via a reviewed PR.

/// Orange 150 rental terms.
abstract final class RentalTerms {
  /// Saved in bookings.terms_version when a customer signs.
  static const String version = '2026-11';

  /// Late return fee per extra day, in pesos (term 5).
  static const double lateFeePerDay = 200;

  /// The numbered terms, in order.
  static const List<String> items = [
    'Strictly no down payment, no reservation.',
    'A 50% reservation fee is required to reserve. This fee is '
        'non-refundable.',
    'Rental is 3 days only: day 1 pick-up, day 2 event, day 3 return.',
    'Using the gown on another date is charged per date at a discounted '
        'price.',
    'Returning late is charged ₱200 per extra day.',
    'Returns through your own rider are allowed. Make sure everything is '
        'complete and undamaged.',
    'Check everything included with the item before taking it, to avoid '
        'charges.',
    'Do not put perfume, cologne, or strong liquids on gowns and suits. '
        'Discoloration counts as damage.',
    'Strictly no cancellation once the reservation fee is paid.',
  ];
}
