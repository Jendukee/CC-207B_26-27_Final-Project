import 'package:flutter/material.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/features/inventory/services/inventory_service.dart';
import 'package:orange150_rental/features/inventory/screens/item_form_screen.dart';

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
        _errorMessage = e.toString();
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

  Future<void> _openForm({String? itemId}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemFormScreen(itemId: itemId)));

    if (!mounted) return;
    await _loadItems();
  }

  String _formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }

  Color _conditionColor(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.available:
        return Colors.green;
      case ItemCondition.cleaningRepair:
        return Colors.orange;
      case ItemCondition.retired:
        return Colors.grey;
    }
  }

  Widget _buildItemCard(Item item) {
    final conditionColor = _conditionColor(item.condition);

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: conditionColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.condition.label,
                    style: TextStyle(
                      color: conditionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(item.description),
                ],
                if (item.inclusions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Inclusions: ${item.inclusions.join(", ")}',
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Unable to load inventory.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadItems, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checkroom_outlined,
                size: 64,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              Text(
                _items.isEmpty
                    ? 'No inventory items yet.'
                    : 'No items match your search.',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add an item or adjust your search and filter.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
            padding: const EdgeInsets.all(16),
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
                hintText: 'Search inventory...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<ItemCondition?>(
              initialValue: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Filter by condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem<ItemCondition?>(
                  value: null,
                  child: Text('All active items'),
                ),
                ...ItemCondition.values.map(
                  (condition) => DropdownMenuItem<ItemCondition?>(
                    value: condition,
                    child: Text(condition.label),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
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
