// Staff inventory: search, condition filter, item cards and Add Item.
//
// UI audit changes: retired items can be reached (#10), errors are plain
// language (#12), the condition chip uses readable AppColors with white
// text (#19), long descriptions no longer overflow the card (#22), prices
// use the shared Formatters (#23), shared Loading/Error/Empty views (#28),
// a labelled search field (#29), condition chips, go_router navigation to
// the item form and room for the Add Item button (#30).
//
// Shop-side redesign (Phase 2): like the customer Browse page, a light grey
// page, the search and the condition chips pinned on a white bar, and a
// 2-column grid of item cards (photo, condition chip, name, type, size,
// price) with skeleton cards while loading (H1, H4, H6). The description
// and inclusions moved off the card to the item form (H8). Data and filters
// are unchanged.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/features/inventory/services/inventory_service.dart';
import 'package:orange150_rental/features/inventory/widgets/inventory_item_card.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Staff inventory management screen.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  List<Item> _items = [];
  ItemCondition? _selectedCondition;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // UI audit #10: load retired items too, so the "Retired" filter works
      // and a retired item can be opened and brought back.
      // _filteredItems hides them unless "Retired" is chosen.
      final items = await _inventoryService.listItems(includeRetired: true);

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = friendlyErrorMessage(
          e,
          fallback: 'Check your connection and try again.',
        );
        _isLoading = false;
      });
    }
  }

  List<Item> get _filteredItems {
    final search = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesSearch =
          search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.type.label.toLowerCase().contains(search) ||
          item.size.toLowerCase().contains(search) ||
          item.ageGroup.label.toLowerCase().contains(search);

      // "All" means all ACTIVE items: retired ones only appear when the
      // "Retired" filter is chosen.
      final matchesCondition = _selectedCondition == null
          ? item.condition != ItemCondition.retired
          : item.condition == _selectedCondition;

      return matchesSearch && matchesCondition;
    }).toList();
  }

  /// Opens the item form through go_router (UI audit #30), so the address
  /// bar and Back work like everywhere else:
  ///   /shop/inventory/new  or  /shop/inventory/:itemId/edit
  Future<void> _openForm({String? itemId}) async {
    await context.push(
      itemId == null
          ? '${RoutePaths.inventory}/new'
          : '${RoutePaths.inventory}/$itemId/edit',
    );

    if (!mounted) return;
    await _loadItems();
  }

  Widget _buildBody() {
    // Shop-side redesign: grey skeleton cards in the grid while loading
    // (H1), like Browse; the shared error (Retry) and empty views (#28).
    if (_isLoading) {
      return const CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: InventoryGridSkeleton(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: 'Unable to load inventory. $_errorMessage',
        onRetry: _loadItems,
      );
    }

    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return EmptyView(
        icon: Icons.checkroom_outlined,
        message: _items.isEmpty
            ? 'No inventory items yet. Add your first gown or suit.'
            : 'No items match your search or filter.',
        actionLabel: _items.isEmpty ? 'Add item' : 'Show all items',
        onAction: _items.isEmpty
            ? () => _openForm()
            : () {
                _searchController.clear();
                setState(() => _selectedCondition = null);
              },
      );
    }

    // Shop-side redesign: a 2-column grid of Browse-style cards (3 from
    // 700 px, 4 from 1000 px). Tapping a card opens the item form.
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            // Extra bottom space so the Add Item button never covers the
            // last card (UI audit #30).
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid.builder(
                gridDelegate: inventoryGridDelegate(
                  constraints.crossAxisExtent,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return InventoryItemCard(
                    item: item,
                    onTap: () => _openForm(itemId: item.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        // Staff header: dark maroon, as on the Dashboard.
        backgroundColor: AppColors.maroonDeep,
        showLogo: false, // no hanger mark on staff headers
        titleSpacing: 40, // same title position as the Dashboard
        title: 'Inventory',
        actions: [
          IconButton(
            tooltip: 'Refresh inventory',
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Shop-side redesign: search and chips pinned on a white bar.
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        // UI audit #29: a visible label, not a placeholder only.
                        labelText: 'Search inventory',
                        hintText: 'Name, type, size or age group',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // UI audit #30: a single-choice filter with 4 options is shown
                  // as chips (one tap, all options visible) instead of a dropdown.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        for (final condition in <ItemCondition?>[
                          null,
                          ...ItemCondition.values,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                condition?.label ?? 'All active items',
                              ),
                              selected: _selectedCondition == condition,
                              onSelected: (_) => setState(
                                () => _selectedCondition = condition,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
