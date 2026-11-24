// Browse tab (the customer home), in the Figma layout:
//   * maroon "Browse" app bar over a white page
//   * a search field and a maroon filter button, then text category tabs
//     (All, Gowns, Long Gowns, Suits, Bearer, Kids, Adult). Both stay
//     pinned at the top while scrolling.
//   * "Recommended For You" (or "Search results") with the item count
//   * a product grid: 2 columns on phones, 3 from 700 px, 4 from 1000 px
//   * customer redesign 2: the Orange 150 mark in the header (H4), a heart
//     on every card and a Favorites heart pinned at the end of the
//     category tabs (H6, H7)
//
// Filter logic (kept from the customer redesign, Phase 1):
//   * the filter button opens the filter bottom sheet (type, age group,
//     size, price range, event date) with Reset / Apply; its badge shows
//     how many filters are on
//   * category tabs switch their filter on / off; "All" clears them
//   * an event date filter shows a banner with a clear button
//   * cards show "Few dates left" (item_busy_days, migration 0010) or
//     "Available on your date"
//   * skeleton cards while loading; ErrorView with Retry; EmptyView with
//     "Clear filters"; pull to refresh
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/features/catalog/services/catalog_service.dart';
import 'package:orange150_rental/features/catalog/widgets/category_row.dart';
import 'package:orange150_rental/features/catalog/widgets/favorites_shortcut.dart';
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

  /// Side padding of the page (design: 20 px).
  static const double _side = 20;

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

  /// Removes the search text and every filter.
  void _clearAll() {
    _search.clear();
    _apply(const ItemFilter());
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
      backgroundColor: theme.colorScheme.surface,
      // Customer redesign 2: the shared header with the Orange 150 mark (H4).
      appBar: const BrandAppBar(
        title: 'Browse',
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search + filter button + category tabs, pinned.
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeader(
                height: _PinnedHeader.extent,
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      _searchRow(theme),
                      CategoryRow(
                        filter: _filter,
                        onTap: (category) => _apply(category.toggleIn(_filter)),
                        onAll: () => _apply(
                          _filter.copyWith(
                            clearType: true,
                            clearAgeGroup: true,
                          ),
                        ),
                        // Customer redesign 2: Favorites, pinned at the end.
                        trailing: const FavoritesShortcut(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_filter.eventDate != null)
              SliverToBoxAdapter(child: _dateBanner()),
            ..._results(),
          ],
        ),
      ),
    );
  }

  /// Search field and the maroon filter button (opens the filter sheet).
  Widget _searchRow(ThemeData theme) {
    final active = _filter.activeCount;
    final border = theme.colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_side, 18, _side, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              // Low #29: the design keeps a placeholder only, so screen
              // readers get this label instead of a visible one.
              child: Semantics(
                label: 'Search gowns and suits',
                textField: true,
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (text) =>
                      _apply(_filter.copyWith(query: text.trim())),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _search,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _search.clear();
                                _apply(_filter.copyWith(query: ''));
                              },
                            ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.maroon),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button with the number of active filters.
          Tooltip(
            message: active == 0 ? 'Filters' : 'Filters ($active on)',
            child: Material(
              color: AppColors.maroon,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _openFilters,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: Badge(
                      isLabelVisible: active > 0,
                      label: Text('$active'),
                      backgroundColor: AppColors.gold,
                      textColor: AppColors.textPrimary,
                      child: const Icon(
                        Icons.tune,
                        color: AppColors.onMaroon,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Showing items free on Dec 24, 2026" with a clear button.
  Widget _dateBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(_side, 4, _side, 0),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(10),
      ),
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

  /// "Recommended For You" / "Search results" and the item count.
  Widget _sectionHeader(int? count) {
    final searching = _filter.activeCount > 0 || _filter.query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_side, 20, _side, 16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                searching ? 'Search results' : 'Recommended For You',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  /// Section header plus skeleton, error, empty or the grid, as slivers.
  List<Widget> _results() {
    return [
      FutureBuilder<_BrowseData>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final count = loading || snapshot.hasError
              ? null
              : snapshot.requireData.items.length;
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _sectionHeader(count)),
              _resultBody(snapshot, loading),
            ],
          );
        },
      ),
    ];
  }

  Widget _resultBody(AsyncSnapshot<_BrowseData> snapshot, bool loading) {
    if (loading) {
      return const SliverPadding(
        padding: EdgeInsets.fromLTRB(_side, 0, _side, 24),
        sliver: ProductGridSkeleton(),
      );
    }
    if (snapshot.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: friendlyErrorMessage(
            snapshot.error!,
            fallback: 'Unable to load items. Please try again.',
          ),
          onRetry: _refresh,
        ),
      );
    }
    final data = snapshot.requireData;
    if (data.items.isEmpty) {
      final filtered = _filter.activeCount > 0 || _filter.query.isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.search_off,
          message: filtered
              ? 'No items found. Try changing or clearing your search and '
                    'filters.'
              : 'No gowns or suits are available right now.',
          actionLabel: filtered ? 'Clear filters' : null,
          onAction: filtered ? _clearAll : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(_side, 0, _side, 24),
      // SliverLayoutBuilder gives the grid width for the column count.
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) => SliverGrid.builder(
          gridDelegate: productGridDelegate(constraints.crossAxisExtent),
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
      ),
    );
  }
}

/// Keeps the search row and category tabs visible at the top.
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({required this.height, required this.child});

  /// Search row (18 + 48 + 12) + category tabs (48).
  static const double extent = 126;

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(_PinnedHeader oldDelegate) => true;
}
