// Staff inventory: search, condition filter, item cards and Add Item.
//
// UI audit changes: retired items can be reached (#10), errors are plain
// language (#12), the condition chip uses readable AppColors with white
// text (#19), long descriptions no longer overflow the card (#22), prices
// use the shared Formatters (#23), shared Loading/Error/Empty views (#28),
// a labelled search field (#29), condition chips, go_router navigation to
// the item form and room for the Add Item button (#30).
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
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/inventory/services/inventory_service.dart';
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

  /// "₱3,500.00" (shared format, UI audit #23).
  String _formatPrice(double price) => Formatters.peso(price);

  /// Chip colors dark enough for white text (UI audit #19), the same
  /// palette as the booking status chips.
  Color _conditionColor(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.available:
        return AppColors.success;
      case ItemCondition.cleaningRepair:
        return AppColors.warningOrange;
      case ItemCondition.retired:
        return AppColors.neutralGrey;
    }
  }

  Widget _buildItemCard(Item item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: item.photoUrls.isNotEmpty
                ? Image.network(
                    item.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Center(child: Icon(Icons.broken_image, size: 48)),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.checkroom, size: 64)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit item',
                      onPressed: () => _openForm(itemId: item.id),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${item.type.label} • ${item.ageGroup.label}'),
                Text(
                  'Size: ${item.size.isEmpty ? "Not specified" : item.size}',
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                StatusChip(
                  label: item.condition.label,
                  color: _conditionColor(item.condition),
                ),
                // UI audit #22: the card has a fixed height, so long text
                // is cut with "..." instead of overflowing.
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.inclusions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Inclusions: ${item.inclusions.join(", ")}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // UI audit #28: the shared loading, error (Retry) and empty views.
    if (_isLoading) {
      return const LoadingView(message: 'Loading inventory...');
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

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final columns = width >= 1200
              ? 4
              : width >= 900
              ? 3
              : width >= 600
              ? 2
              : 1;

          return GridView.builder(
            // Extra bottom space so the Add Item button never covers the
            // last card (UI audit #30).
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 560,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return _buildItemCard(filteredItems[index]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final condition in <ItemCondition?>[
                  null,
                  ...ItemCondition.values,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(condition?.label ?? 'All active items'),
                      selected: _selectedCondition == condition,
                      onSelected: (_) =>
                          setState(() => _selectedCondition = condition),
                    ),
                  ),
              ],
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
