// "Rental agreement" card on the checkout (customer redesign, Phase 2): the
// shop's paper reservation form as a clean digital form.
//
//   * shop header, filled-in fields, free accessories and the numbered
//     terms are READ-ONLY (shared AgreementDocument)
//   * editable: Facebook account, Shoes size / Long sleeves size (only when
//     those come with the item) and Note
//   * signature replacement: "Type your full name to sign" (must match the
//     full name in Card 1, ignoring case and extra spaces) and the
//     "I have read and agree..." checkbox, then the date and time of
//     signing
//
// Display only: the checkout owns the controllers and the agreed flag.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/agreement_document.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';

/// The e-contract with its signature fields.
class RentalAgreementCard extends StatelessWidget {
  /// Creates the card.
  const RentalAgreementCard({
    super.key,
    required this.form,
    required this.facebook,
    required this.note,
    required this.shoeSize,
    required this.longSleevesSize,
    required this.signature,
    required this.agreed,
    required this.onAgreedChanged,
    required this.onChanged,
    this.signedAt,
    this.enabled = true,
  });

  /// The filled-in form (from the other checkout cards).
  final AgreementForm form;

  /// Editable fields.
  final TextEditingController facebook;
  final TextEditingController note;
  final TextEditingController shoeSize;
  final TextEditingController longSleevesSize;

  /// "Type your full name to sign".
  final TextEditingController signature;

  /// The agreement checkbox.
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;

  /// Called whenever an editable field changes (to refresh the summary).
  final VoidCallback onChanged;

  /// When both signature parts became valid; null while not signed.
  final DateTime? signedAt;

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
    final theme = Theme.of(context);
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
        const Divider(height: 24),

        // Signature replacement.
        Text('Signature', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: signature,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Type your full name to sign *',
            helperText: 'Same as the full name in Contact details',
          ),
          validator: (value) =>
              AgreementRules.validateSignature(value, form.fullName),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: agreed,
          onChanged: enabled ? (v) => onAgreedChanged(v ?? false) : null,
          title: const Text(
            'I have read and agree to the rental terms of Orange 150. *',
          ),
        ),
        Text(
          signedAt == null
              ? 'Not signed yet.'
              : 'Signed on ${Formatters.dateTime(signedAt!)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
