// "How to pay" instructions with the shop's GCash number and contact
// numbers already filled in (customer redesign, Phase 3). Used on the
// "Request submitted" screen and on a Pending booking's details, so both
// always show the same, correct numbers from core/config/shop_contact.dart.
//
//   * GCash (or no method chosen): the GCash number with Copy, and the
//     reference number to put in the message.
//   * Cash: the shop address.
//   * Bank: ask the shop for the account details.
//   * Always: the shop's contact numbers, each with Copy.
//
// [method] is the bookings.preferred_payment_method value ('cash', 'gcash',
// 'bank' or null), so core does not import the reservation feature.
//
// Example:
//   PaymentInstructions(method: booking.preferredPaymentMethod,
//                       referenceNo: booking.referenceNo)
//
// Shop settings (0016): the GCash number, address and contact numbers now
// come from ShopSettingsService (the owner can change them). Until the
// settings load, or if they cannot load, the shop_contact.dart values are
// shown, so the instructions are never empty. The widget redraws when the
// settings arrive.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/services/shop_settings_service.dart';
import 'package:orange150_rental/core/widgets/contact_shop.dart';

/// Payment instructions for one booking.
class PaymentInstructions extends StatelessWidget {
  /// Creates the instructions for [method] and [referenceNo].
  const PaymentInstructions({
    super.key,
    required this.method,
    required this.referenceNo,
  });

  /// 'cash', 'gcash', 'bank' or null (shown like GCash).
  final String? method;

  /// The booking reference to quote with the payment.
  final String referenceNo;

  @override
  Widget build(BuildContext context) {
    final service = ShopSettingsService.instance..ensureLoaded();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => _build(context, service),
    );
  }

  Widget _build(BuildContext context, ShopSettingsService service) {
    final theme = Theme.of(context);
    final settings = service.current;
    final isGcash = method == null || method == 'gcash';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGcash) ...[
          const Text('Send the amount to our GCash number:'),
          _CopyRow(
            value: settings.gcashNumber,
            style: theme.textTheme.titleLarge,
            tooltip: 'Copy GCash number',
            copied: 'GCash number copied.',
          ),
          Text(
            'Put your reference number $referenceNo in the message, then '
            'send the screenshot to the shop.',
          ),
        ],
        if (method == 'cash')
          Text('Pay in cash at the shop: ${settings.address}.'),
        if (method == 'bank')
          const Text(
            'Contact the shop for the bank account details, then send a '
            'photo of the deposit slip.',
          ),
        const SizedBox(height: 12),
        // The shop's numbers, pre-filled, for sending the proof or asking.
        const Text('Shop contact numbers:'),
        for (final phone in settings.contactNumbers)
          _CopyRow(
            value: phone,
            style: theme.textTheme.titleMedium,
            tooltip: 'Copy $phone',
            copied: 'Number copied.',
          ),
      ],
    );
  }
}

/// A selectable value with a 48 px Copy button.
class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.value,
    required this.style,
    required this.tooltip,
    required this.copied,
  });

  final String value;
  final TextStyle? style;
  final String tooltip;
  final String copied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SelectableText(value, style: style)),
        IconButton(
          tooltip: tooltip,
          onPressed: () => copyWithSnack(context, value, copied),
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }
}
