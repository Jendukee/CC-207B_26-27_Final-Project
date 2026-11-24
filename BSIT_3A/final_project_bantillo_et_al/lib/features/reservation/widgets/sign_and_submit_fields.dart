// The signature part of the e-contract, shown in the checkout's LAST card,
// "Sign and submit", right above the sticky Submit bar (customer redesign
// 2, Phase 1). Moved out of the agreement card so the customer reads the
// whole form and the terms before signing.
//
//   * one line: "By signing, you agree to the rental terms above."
//   * "Type your full name to sign *": must match the full name in Card 1,
//     ignoring case and extra spaces (same rule as before)
//   * the "I have read and agree..." checkbox
//   * "Signed on <date and time>" once both are valid, else "Not signed yet."
//
// Heuristics: H6 recognition rather than recall (everything is read before
// signing), H5 error prevention (Submit stays disabled until signed, and
// the name is checked as it is typed).
//
// Display only: the checkout owns the controller and the agreed flag.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/reservation/models/agreement_form.dart';

/// Signature field, agreement checkbox and signing time.
class SignAndSubmitFields extends StatelessWidget {
  /// Creates the fields. [fullName] is the name from Card 1.
  const SignAndSubmitFields({
    super.key,
    required this.fullName,
    required this.signature,
    required this.agreed,
    required this.onAgreedChanged,
    required this.onChanged,
    this.signedAt,
    this.enabled = true,
  });

  /// The full name in Contact details (Card 1).
  final String fullName;

  /// "Type your full name to sign".
  final TextEditingController signature;

  /// The agreement checkbox.
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;

  /// Called when the typed name changes.
  final VoidCallback onChanged;

  /// When both parts became valid; null while not signed.
  final DateTime? signedAt;

  /// False while submitting.
  final bool enabled;

  /// The explanation under the card title.
  static const String explanation =
      'By signing, you agree to the rental terms above.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(explanation),
        const SizedBox(height: 12),
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
              AgreementRules.validateSignature(value, fullName),
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
        // Live region: screen readers hear when the form becomes signed.
        Semantics(
          liveRegion: true,
          child: Text(
            signedAt == null
                ? 'Not signed yet.'
                : 'Signed on ${Formatters.dateTime(signedAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
