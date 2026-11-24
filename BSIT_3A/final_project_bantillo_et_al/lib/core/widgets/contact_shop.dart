// "Contact the shop" button and dialog (UI audit, finding #9, heuristic
// H10): a human fallback whenever the app (or the AI assistant) cannot
// help. The dialog shows the shop number from core/config/shop_contact.dart
// with two actions:
//   * Call  - opens the phone dialer (url_launcher, tel: link)
//   * Copy  - copies the number to the clipboard
//
// Example:
//   const ContactShopButton()
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orange150_rental/core/config/shop_contact.dart';

/// A text button with a phone icon that opens [showContactShopDialog].
class ContactShopButton extends StatelessWidget {
  /// Creates the button.
  const ContactShopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showContactShopDialog(context),
      icon: const Icon(Icons.support_agent),
      label: const Text('Contact the shop'),
    );
  }
}

/// Shows the shop's number with Call and Copy buttons.
Future<void> showContactShopDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final messenger = ScaffoldMessenger.of(context);
      final numberSet = ShopContact.isPhoneSet;

      /// Opens the dialer; some devices (e.g. desktop web) cannot call.
      Future<void> call() async {
        final opened = await launchUrl(
          Uri(scheme: 'tel', path: ShopContact.phone),
        );
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

      /// Copies the number and confirms with a snackbar.
      Future<void> copy() async {
        await Clipboard.setData(const ClipboardData(text: ShopContact.phone));
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Shop number copied.')),
        );
      }

      return AlertDialog(
        icon: const Icon(Icons.support_agent),
        title: const Text('Contact the shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              numberSet
                  ? 'Call or message ${ShopContact.name} for help with '
                        'sizes, dates, payments or your booking.'
                  : 'The shop number has not been set yet.',
              textAlign: TextAlign.center,
            ),
            if (numberSet) ...[
              const SizedBox(height: 12),
              SelectableText(
                ShopContact.phone,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: numberSet ? copy : null,
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          FilledButton.icon(
            onPressed: numberSet ? call : null,
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ],
      );
    },
  );
}
