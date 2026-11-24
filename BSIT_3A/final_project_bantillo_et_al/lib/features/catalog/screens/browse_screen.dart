// Browse tab (the customer home), laid out like a shopping app (customer
// redesign, Phase 1):
//   * a search bar that stays at the top while scrolling, with a filter
//     icon (badge = number of active filters)
//   * a horizontal category row: Gowns, Long Gowns, Suits, Bearer, Kids,
//     Adult
//   * a 2-column product grid (more columns on tablets / web)
//   * a filter bottom sheet (type, age group, size, price, event date)
//   * skeleton cards while loading, EmptyView / ErrorView with actions
//
// Product cards show "Available on your date" when the customer filtered
// by event date, or "Few dates left" when most of the next 30 days are
// booked (item_busy_days, migration 0010).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/features/catalog/services/catalog_service.dart';
import 'package:orange150_rental/features/catalog/widgets/category_row.dart';
import 'package:orange150_rental/features/catalog/widgets/filter_sheet.dart';
import 'package:orange150_rental/features/catalog/widgets/product_card.dart';
import 'package:orange150_rental/features/catalog/widgets/product_grid_skeleton.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Items plus the busy-day counts used for the tags.
class _BrowseData {
  const _BrowseData(this.items, this.busyDays);

  final List<Item> items;
  final Map<String, int> busyDays;
}

/// The Browse screen.
class BrowseScreen extends StatefulWidget {
  /// Creates the screen.
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final CatalogService _service = CatalogService();
  final TextEditingController _search = TextEditingController();

  ItemFilter _filter = const ItemFilter();
  late Future<_BrowseData> _future;

  /// Sizes for the filter sheet (loaded once; empty if it fails).
  List<String> _sizes = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _service.listSizes().then((s) {
      if (mounted) setState(() => _sizes = s);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Loads the items for [_filter] and, when no date is chosen, the busy
  /// counts for "Few dates left".
  Future<_BrowseData> _load() async {
    final filter = _filter;
    final results = await Future.wait<Object>([
      _service.searchItems(filter),
      if (filter.eventDate == null) _service.busyDays(),
    ]);
    return _BrowseData(
      results[0] as List<Item>,
      results.length > 1 ? results[1] as Map<String, int> : const {},
    );
  }

  /// Applies a new filter and reloads.
  void _apply(ItemFilter filter) {
    setState(() {
      _filter = filter;
      _future = _load();
    });
  }

  /// Pull to refresh.
  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {
      // ErrorView shows it.
    }
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(
      context,
      current: _filter,
      sizes: _sizes,
    );
    if (result != null) _apply(result);
  }

  void _openItem(Item item) => context.pushNamed(
    RouteNames.itemDetails,
    pathParameters: {'itemId': item.id},
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Light grey page so the white cards stand out.
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _searchBar(theme),
            SliverToBoxAdapter(
              child: Container(
                color: theme.colorScheme.surface,
                child: CategoryRow(
                  filter: _filter,
                  onTap: (category) => _apply(category.toggleIn(_filter)),
                ),
              ),
            ),
            if (_filter.eventDate != null)
              SliverToBoxAdapter(child: _dateBanner(theme)),
            ..._results(),
          ],
        ),
      ),
    );
  }

  /// Search field in a maroon bar that stays at the top (pinned).
  Widget _searchBar(ThemeData theme) {
    final active = _filter.activeCount;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 68,
      titleSpacing: 12,
      title: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onSubmitted: (text) => _apply(_filter.copyWith(query: text.trim())),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search gowns, suits, barong…',
          filled: true,
          fillColor: theme.colorScheme.surface,
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _search,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _apply(_filter.copyWith(query: ''));
                    },
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: active == 0 ? 'Filters' : 'Filters ($active on)',
          onPressed: _openFilters,
          icon: Badge(
            isLabelVisible: active > 0,
            label: Text('$active'),
            backgroundColor: AppColors.gold,
            textColor: AppColors.textPrimary,
            child: const Icon(Icons.tune),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// "Showing items free on Dec 24, 2026" with a clear button.
  Widget _dateBanner(ThemeData theme) {
    return Container(
      color: AppColors.goldTint,
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          const Icon(Icons.event_available, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing items free on ${Formatters.date(_filter.eventDate!)}',
            ),
          ),
          IconButton(
            tooltip: 'Remove event date',
            onPressed: () => _apply(_filter.copyWith(clearEventDate: true)),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  /// Skeleton, error, empty or the grid, as slivers.
  List<Widget> _results() {
    return [
      FutureBuilder<_BrowseData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SliverPadding(
              padding: EdgeInsets.all(8),
              sliver: ProductGridSkeleton(),
            );
          }
          if (snapshot.hasError) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: friendlyErrorMessage(
                  snapshot.error!,
                  fallback: 'Could not load items. Please try again.',
                ),
                onRetry: _refresh,
              ),
            );
          }
          final data = snapshot.requireData;
          if (data.items.isEmpty) {
            final filtered = _filter.activeCount > 0 || _filter.query != '';
            return SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off,
                message: filtered
                    ? 'No items match your search. Try other filters.'
                    : 'No gowns or suits are available right now.',
                actionLabel: filtered ? 'Clear filters' : null,
                onAction: filtered
                    ? () {
                        _search.clear();
                        _apply(const ItemFilter());
                      }
                    : null,
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid.builder(
              gridDelegate: productGridDelegate,
              itemCount: data.items.length,
              itemBuilder: (context, index) {
                final item = data.items[index];
                return ProductCard(
                  item: item,
                  onTap: () => _openItem(item),
                  tag: AvailabilityRules.tagFor(
                    searchedByDate: _filter.eventDate != null,
                    busyDays: data.busyDays[item.id] ?? 0,
                  ),
                );
              },
            ),
          );
        },
      ),
    ];
  }
}
