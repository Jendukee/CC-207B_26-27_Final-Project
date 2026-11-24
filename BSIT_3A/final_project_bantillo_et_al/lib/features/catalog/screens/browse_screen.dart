import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/features/catalog/services/catalog_service.dart';
import 'package:orange150_rental/shared/models/item.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final CatalogService _catalogService = CatalogService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  ItemType? _selectedType;
  AgeGroup? _selectedAgeGroup;
  DateTime? _selectedEventDate;
  bool _showFilters = false;

  List<Item> _items = [];
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
    _sizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final priceText = _priceController.text.trim();
      final maxPrice = priceText.isEmpty ? null : double.tryParse(priceText);

      if (priceText.isNotEmpty && maxPrice == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid maximum price.';
        });
        return;
      }

      final filter = ItemFilter(
        query: _searchController.text.trim(),
        type: _selectedType,
        ageGroup: _selectedAgeGroup,
        size: _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim(),
        maxPrice: maxPrice,
        eventDate: _selectedEventDate,
      );

      final results = await _catalogService.searchItems(filter);

      if (!mounted) return;

      setState(() {
        _items = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load items. Please try again.';
      });
    }
  }

  Future<void> _pickEventDate() async {
    final today = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedEventDate = pickedDate;
    });

    await _loadItems();
  }

  void _clearFilters() {
    _searchController.clear();
    _sizeController.clear();
    _priceController.clear();

    setState(() {
      _selectedType = null;
      _selectedAgeGroup = null;
      _selectedEventDate = null;
    });

    _loadItems();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<ItemType>(
              initialValue: _selectedType,
              hint: const Text('All types'),
              decoration: const InputDecoration(
                labelText: 'Item type',
                border: OutlineInputBorder(),
              ),
              items: ItemType.values
                  .map(
                    (type) => DropdownMenuItem<ItemType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<AgeGroup>(
              initialValue: _selectedAgeGroup,
              hint: const Text('All age groups'),
              decoration: const InputDecoration(
                labelText: 'Age group',
                border: OutlineInputBorder(),
              ),
              items: AgeGroup.values
                  .map(
                    (group) => DropdownMenuItem<AgeGroup>(
                      value: group,
                      child: Text(group.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAgeGroup = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size',
                hintText: 'e.g. S, M, L, XL',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Maximum rental price',
                hintText: 'Enter budget',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickEventDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedEventDate == null
                    ? 'Select event date'
                    : 'Event date: ${_formatDate(_selectedEventDate!)}',
              ),
            ),

            if (_selectedEventDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedEventDate = null;
                  });
                },
                child: const Text('Remove event date'),
              ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadItems,
                child: const Text('Apply Filters'),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            RouteNames.itemDetails,
            pathParameters: {'itemId': item.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: item.photoUrls.isNotEmpty
                  ? Image.network(
                      item.photoUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        );
                      },
                    )
                  : const Center(child: Icon(Icons.image, size: 48)),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text('${item.type.label} • ${item.ageGroup.label}'),

                  const SizedBox(height: 4),

                  Text('Size: ${item.size}'),

                  const SizedBox(height: 8),

                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward, size: 16),
                      SizedBox(width: 4),
                      Text('View details'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid() {
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48),
              SizedBox(height: 12),
              Text('No items found.', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(
                'Try changing or clearing your filters.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1000
            ? 4
            : width >= 650
            ? 3
            : width >= 400
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 0.55 : 0.45,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return _buildItemCard(_items[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _loadItems(),
                        decoration: InputDecoration(
                          hintText: 'Search gowns, suits...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _loadItems,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(_showFilters ? Icons.close : Icons.tune),
                      tooltip: _showFilters ? 'Close filters' : 'Open filters',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showFilters)
                const Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Filter panel opened successfully.'),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  '${_items.length} item(s) found',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadItems,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildItemGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
