// "Contact the shop" button and dialog (UI audit #9, heuristic H10): a
// human fallback whenever the app (or the AI assistant) cannot help.
// Everything shown comes from core/config/shop_contact.dart:
//   * shop name and address
//   * both contact numbers, each with Call (dialer) and Copy
//   * the GCash number for payments, with Copy
//
// Examples:
//   const ContactShopButton()                 // text button
//   const ContactShopButton(outlined: true)   // outlined, e.g. on a card
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orange150_rental/core/config/shop_contact.dart';

/// A button with a support icon that opens [showContactShopDialog].
class ContactShopButton extends StatelessWidget {
  /// Creates the button. [outlined] draws a border (for use on cards).
  const ContactShopButton({super.key, this.outlined = false});

  /// True for an OutlinedButton, false for a TextButton.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.support_agent);
    const label = Text('Contact the shop');
    void open() => showContactShopDialog(context);
    return outlined
        ? OutlinedButton.icon(onPressed: open, icon: icon, label: label)
        : TextButton.icon(onPressed: open, icon: icon, label: label);
  }
}

/// Copies [text] and confirms with a snackbar.
Future<void> copyWithSnack(
  BuildContext context,
  String text,
  String confirmation,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(SnackBar(content: Text(confirmation)));
}

/// Shows the shop details with Call and Copy buttons.
Future<void> showContactShopDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final messenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(dialogContext);

      /// Opens the dialer; some devices (e.g. desktop web) cannot call.
      Future<void> call(String number) async {
        final opened = await launchUrl(Uri(scheme: 'tel', path: number));
        if (!opened) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Calling is not available on this device. '
                'Copy the number instead.',
              ),
            ),
          );
        }
      }

      /// One number with Call and Copy buttons.
      Widget numberRow(String number, {required bool canCall}) => Row(
        children: [
          Expanded(
            child: SelectableText(number, style: theme.textTheme.titleMedium),
          ),
          if (canCall)
            IconButton(
              tooltip: 'Call $number',
              onPressed: () => call(number),
              icon: const Icon(Icons.call),
            ),
          IconButton(
            tooltip: 'Copy $number',
            onPressed: () => copyWithSnack(context, number, 'Number copied.'),
            icon: const Icon(Icons.copy),
          ),
        ],
      );

      return AlertDialog(
        icon: const Icon(Icons.support_agent),
        title: const Text('Contact the shop'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ShopContact.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(ShopContact.address),
              const SizedBox(height: 16),
              Text('Call or text', style: theme.textTheme.labelLarge),
              for (final number in ShopContact.phones)
                numberRow(number, canCall: true),
              const SizedBox(height: 8),
              Text('GCash (payments)', style: theme.textTheme.labelLarge),
              numberRow(ShopContact.gcash, canCall: false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
