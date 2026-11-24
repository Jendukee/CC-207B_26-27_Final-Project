// The rental agreement drawn as a clean digital version of the shop's paper
// form (customer redesign, Phase 2): shop header (name, address, contact
// numbers, GCash), the filled-in fields as label / value rows, the free
// accessories, and the numbered terms and conditions.
//
// Used in three places, so all three look the same:
//   * checkout: the live form before signing (reservation feature)
//   * customer booking details: the saved, signed agreement
//   * staff booking details: the saved, signed agreement
// For saved bookings, build it with AgreementDocument.fromSnapshot from
// bookings.terms_snapshot, so it shows exactly what the customer signed,
// even if the terms change later.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/config/rental_terms.dart';
import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';

/// Read-only agreement document.
class AgreementDocument extends StatelessWidget {
  /// Creates the document from its parts.
  const AgreementDocument({
    super.key,
    required this.rows,
    required this.accessories,
    required this.terms,
    this.shopName = ShopContact.name,
    this.shopAddress = ShopContact.address,
    this.shopPhones = ShopContact.phones,
    this.shopGcash = ShopContact.gcash,
    this.accessoriesNote,
    this.extraRows = const [],
  });

  /// Builds it from a saved bookings.terms_snapshot (see AgreementForm).
  factory AgreementDocument.fromSnapshot(Map<String, dynamic> snapshot) {
    final shop = snapshot['shop'] as Map<String, dynamic>? ?? const {};
    List<String> strings(Object? value) => [
      for (final v in (value as List?) ?? const []) '$v',
    ];
    return AgreementDocument(
      shopName: shop['name'] as String? ?? ShopContact.name,
      shopAddress: shop['address'] as String? ?? ShopContact.address,
      shopPhones: strings(shop['phones']),
      shopGcash: shop['gcash'] as String? ?? '',
      rows: [
        for (final row in (snapshot['rows'] as List?) ?? const [])
          ('${(row as Map)['label'] ?? ''}', '${row['value'] ?? ''}'),
      ],
      accessories: strings(snapshot['accessories']),
      accessoriesNote: snapshot['accessories_note'] as String?,
      terms: strings(snapshot['terms']).isEmpty
          ? RentalTerms.items
          : strings(snapshot['terms']),
    );
  }

  final String shopName;
  final String shopAddress;
  final List<String> shopPhones;
  final String shopGcash;

  /// Filled-in fields, in form order.
  final List<(String, String)> rows;

  /// Free accessories included with the item.
  final List<String> accessories;

  /// Note under the accessories.
  final String? accessoriesNote;

  /// Numbered terms and conditions.
  final List<String> terms;

  /// Widgets placed after the rows (e.g. editable fields at checkout).
  final List<Widget> extraRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shop header, like the top of the paper form.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.goldTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                shopName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(shopAddress, textAlign: TextAlign.center),
              if (shopPhones.isNotEmpty)
                Text(
                  'Contact: ${shopPhones.join(' / ')}',
                  textAlign: TextAlign.center,
                ),
              if (shopGcash.isNotEmpty)
                Text('GCash: $shopGcash', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('RESERVATION FORM', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        const SizedBox(height: 12),

        for (final (label, value) in rows) _FormRow(label: label, value: value),
        ...extraRows,

        const SizedBox(height: 12),
        Text('Accessories', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (accessories.isEmpty)
          const Text('No accessories come with this item.')
        else
          for (final accessory in accessories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_box,
                    size: 20,
                    color: AppColors.maroon,
                    semanticLabel: 'Included',
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(accessory)),
                ],
              ),
            ),
        if (accessoriesNote != null) ...[
          const SizedBox(height: 4),
          Text(accessoriesNote!, style: theme.textTheme.bodySmall),
        ],

        const SizedBox(height: 12),
        Text('Terms and conditions', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (var i = 0; i < terms.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 24, child: Text('${i + 1}.')),
                Expanded(child: Text(terms[i])),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Label: value" with a light underline, like a filled-in form line.
class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a saved agreement full screen (customer and staff details).
Future<void> showSignedAgreement(
  BuildContext context, {
  required Map<String, dynamic> snapshot,
  required String signedName,
  required DateTime? signedAt,
  String? version,
  // The full name submitted with the booking (0012), shown above the
  // signature line. Null on older bookings.
  String? customerFullName,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Signed rental agreement')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AgreementDocument.fromSnapshot(snapshot),
            const Divider(height: 32),
            if ((customerFullName ?? '').trim().isNotEmpty) ...[
              Text('Name on booking: $customerFullName'),
              const SizedBox(height: 4),
            ],
            Text(
              'Signed as $signedName'
              '${signedAt == null ? '' : ' on ${Formatters.dateTime(signedAt)}'}'
              '${version == null ? '' : ' (terms version $version)'}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
