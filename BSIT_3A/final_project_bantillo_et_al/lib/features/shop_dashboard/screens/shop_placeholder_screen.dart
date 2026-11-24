// "Coming soon" page used for More -> Shop settings and More -> Staff
// accounts until those are built.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';

/// A titled page that explains a feature is not built yet.
class ShopPlaceholderScreen extends StatelessWidget {
  /// Creates the page.
  const ShopPlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  /// App bar title.
  final String title;

  /// What will be here later.
  final String message;

  /// Large icon above the message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shop-side redesign: the same grey page as the other staff screens.
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(title: title),
      body: EmptyView(icon: icon, message: message),
    );
  }
}
