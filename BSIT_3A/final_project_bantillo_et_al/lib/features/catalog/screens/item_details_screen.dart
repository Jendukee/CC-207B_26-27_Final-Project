// Item details, laid out like a product page (customer redesign, Phase 1):
//   * full-width swipeable photo carousel with a page indicator
//   * white section cards on a light grey page: price and name, size,
//     "Inclusions (free accessories)", description, availability calendar
//   * a sticky bottom bar: "Ask" (opens the Assistant) and a full-width
//     maroon "Reserve Now"
//
// Reserve Now:
//   * guests go to Login and come back here afterwards (?from=...)
//   * signed-in customers get the Reserve sheet to pick the event date,
//     then the checkout opens: /reserve/:itemId/checkout?date=yyyy-MM-dd
//     (route defined in reservation_routes.dart; opened by path only)
//
// Customer redesign 2 (Phase 1): the shared BrandAppBar with a favorites
// heart in the header actions (H4, H7); guests reach Login with push, so
// Back returns here (H3).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/services/session_controller.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/sticky_action_bar.dart';
import 'package:orange150_rental/features/catalog/services/catalog_service.dart';
import 'package:orange150_rental/features/catalog/widgets/availability_calendar.dart';
import 'package:orange150_rental/features/catalog/widgets/favorite_button.dart';
import 'package:orange150_rental/features/catalog/widgets/photo_carousel.dart';
import 'package:orange150_rental/features/catalog/widgets/reserve_date_sheet.dart';
import 'package:orange150_rental/core/utils/event_date_rules.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// The item plus its booked days for the availability calendar.
class _DetailsData {
  const _DetailsData(this.item, this.blockedDays);

  final Item item;
  final Set<DateTime> blockedDays;
}

/// Displays the photos and information of one rentable item.
class ItemDetailsScreen extends StatefulWidget {
  /// Creates the screen for [itemId].
  const ItemDetailsScreen({super.key, required this.itemId});

  /// Path parameter from the route.
  final String itemId;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final CatalogService _service = CatalogService();
  late Future<_DetailsData> _future;

  /// Booking window offered: from 2 days ahead, for one year.
  final DateTime _earliest = EventDateRules.earliestEventDate();
  late final DateTime _latest = DateTime(
    _earliest.year + 1,
    _earliest.month,
    _earliest.day,
  );

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailsData> _load() async {
    final item = await _service.getItem(widget.itemId);
    Set<DateTime> blocked;
    try {
      blocked = (await _service.getBlockedDates(
        itemId: widget.itemId,
        from: _earliest.subtract(const Duration(days: 1)),
        to: _latest.add(const Duration(days: 1)),
      )).toSet();
    } catch (_) {
      blocked = {}; // the date is checked again at checkout
    }
    return _DetailsData(item, blocked);
  }

  /// Reserve Now (or tapping a free date on the calendar).
  Future<void> _reserve(_DetailsData data, {DateTime? date}) async {
    // Guests sign in first and come back to this item.
    if (!SessionController.instance.isSignedIn) {
      final here = GoRouterState.of(context).uri.toString();
      // push (not go), so Back from Login returns to this item without
      // reserving (H3). The reason makes Login say why (H2).
      context.pushNamed(
        RouteNames.login,
        queryParameters: {
          'from': here,
          LoginReasons.param: LoginReasons.reserve,
        },
      );
      return;
    }
    final chosen = await showReserveDateSheet(
      context,
      item: data.item,
      blockedDays: data.blockedDays,
      earliest: _earliest,
      latest: _latest,
      initial: date,
    );
    if (chosen == null || !mounted) return;
    // Checkout route of the reservation feature (by path, no import).
    context.push(
      '${RoutePaths.reservePrefix}/${data.item.id}/checkout'
      '?date=${Formatters.isoDate(chosen)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_DetailsData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          // Customer redesign 2: shared header (H4) with the favorites heart.
          appBar: BrandAppBar(
            title: 'Item details',
            actions: [
              FavoriteButton(itemId: widget.itemId, itemName: data?.item.name),
              const SizedBox(width: 4),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when snapshot.hasError => ErrorView(
              message: friendlyErrorMessage(
                snapshot.error!,
                fallback:
                    'This item could not be loaded. It may no longer be '
                    'available.',
              ),
              onRetry: () => setState(() => _future = _load()),
            ),
            ConnectionState.done => _details(data!, theme),
            _ => const LoadingView(message: 'Loading item...'),
          },
          // Sticky Ask / Reserve Now bar once the item is loaded.
          bottomNavigationBar: data == null
              ? null
              : StickyActionBar(
                  leading: OutlinedButton.icon(
                    onPressed: () => context.go(RoutePaths.assistant),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ask'),
                  ),
                  action: FilledButton(
                    onPressed: () => _reserve(data),
                    child: const Text('Reserve Now'),
                  ),
                ),
        );
      },
    );
  }

  Widget _details(_DetailsData data, ThemeData theme) {
    final item = data.item;
    return ListView(
      children: [
        PhotoCarousel(urls: item.photoUrls, label: item.name),
        const SizedBox(height: 8),

        // Price and name.
        SectionCard(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.peso(item.price),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'for the 3-day rental (pick-up, event, return)',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(item.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${item.type.label} · ${item.ageGroup.label}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Size (each item is one size; shown as a chip like a variation).
        SectionCard(
          title: 'Size',
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Wrap(
            children: [
              Chip(
                label: Text(item.size.isEmpty ? 'One size' : item.size),
                side: const BorderSide(color: AppColors.maroon, width: 1.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Inclusions (free accessories)',
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: item.inclusions.isEmpty
              ? const Text('No accessories are included with this item.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final inclusion in item.inclusions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(inclusion)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Accessories come free with the item. Damaged '
                      'accessories will be charged.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
        ),

        if (item.description.isNotEmpty)
          SectionCard(
            title: 'Description',
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(item.description),
          ),

        SectionCard(
          title: 'Availability',
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tap a free date to reserve it as your event date.'),
              const SizedBox(height: 8),
              AvailabilityCalendar(
                blockedDays: data.blockedDays,
                earliest: _earliest,
                latest: _latest,
                onSelect: (date) => _reserve(data, date: date),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
