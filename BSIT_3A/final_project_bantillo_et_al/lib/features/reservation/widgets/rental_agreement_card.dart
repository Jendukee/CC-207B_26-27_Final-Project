// "Rental agreement" card on the checkout (customer redesign, Phase 2): the
// shop's paper reservation form as a clean digital form.
//
//   * shop header, filled-in fields, free accessories and the numbered
//     terms are READ-ONLY (shared AgreementDocument)
//   * editable: Facebook account, Shoes size / Long sleeves size (only when
//     those come with the item) and Note
//   * the signature (typed name, checkbox, signing time) is NOT here any
//     more: customer redesign 2 moved it to the last checkout card, "Sign
//     and submit" (sign_and_submit_fields.dart), so the customer reads
//     everything first (H6, H5)
//
// Display only: the checkout owns the controllers.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/widgets/agreement_document.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';

/// The e-contract (read-only form, terms and the optional fields).
class RentalAgreementCard extends StatelessWidget {
  /// Creates the card.
  const RentalAgreementCard({
    super.key,
    required this.form,
    required this.facebook,
    required this.note,
    required this.shoeSize,
    required this.longSleevesSize,
    required this.onChanged,
    this.enabled = true,
  });

  /// The filled-in form (from the other checkout cards).
  final AgreementForm form;

  /// Editable fields.
  final TextEditingController facebook;
  final TextEditingController note;
  final TextEditingController shoeSize;
  final TextEditingController longSleevesSize;

  /// Called whenever an editable field changes (to refresh the summary).
  final VoidCallback onChanged;

  /// False while submitting.
  final bool enabled;

  /// Rows replaced by input fields on this card.
  static const Set<String> _editableLabels = {
    'Facebook account',
    'Shoes size',
    'Long sleeves size',
    'Note',
  };

  @override
  Widget build(BuildContext context) {
    final inclusions = form.item.inclusions;
    return AgreementDocument(
      rows: [
        for (final row in form.rows())
          if (!_editableLabels.contains(row.$1)) row,
      ],
      accessories: inclusions,
      accessoriesNote: AgreementRules.accessoriesNote,
      terms: RentalTerms.items,
      extraRows: [
        const SizedBox(height: 8),
        _field(
          facebook,
          'Facebook account (optional)',
          helper: 'The shop may message you here about your rental.',
          maxLength: 200,
        ),
        if (AgreementRules.needsShoeSize(inclusions))
          _field(shoeSize, 'Shoes size (optional)', maxLength: 20),
        if (AgreementRules.needsLongSleevesSize(inclusions))
          _field(
            longSleevesSize,
            'Long sleeves size (optional)',
            maxLength: 20,
          ),
        _field(note, 'Note (optional)', maxLength: 500, maxLines: 2),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
    int maxLength = 100,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLength: maxLength,
        maxLines: maxLines,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }
}
