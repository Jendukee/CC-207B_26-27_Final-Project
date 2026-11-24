// Browse tab: search the catalog and filter by type, age group, size,
// maximum price and event date.
//
// UI audit changes: the filter panel is shown (#5), type and age group use
// chips (#21), the price field accepts numbers only (#16), and dates and
// pesos use the shared Formatters (#23).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/utils/validators.dart';
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

  /// A labelled row of ChoiceChips: "All" plus one chip per option.
  /// Picking "All" passes null to [onSelected].
  Widget _choiceRow<T>({
    required String label,
    required String allLabel,
    required List<T> options,
    required String Function(T option) optionLabel,
    required T? selected,
    required ValueChanged<T?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final option in options)
              ChoiceChip(
                label: Text(optionLabel(option)),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
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

            // UI audit #21: 2-option filters are single-choice chips
            // (All / Gown / Suit) instead of dropdowns, so every choice is
            // visible and one tap away.
            _choiceRow<ItemType>(
              label: 'Item type',
              allLabel: 'All types',
              options: ItemType.values,
              optionLabel: (type) => type.label,
              selected: _selectedType,
              onSelected: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 12),

            _choiceRow<AgeGroup>(
              label: 'Age group',
              allLabel: 'All ages',
              options: AgeGroup.values,
              optionLabel: (group) => group.label,
              selected: _selectedAgeGroup,
              onSelected: (group) => setState(() => _selectedAgeGroup = group),
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
              // UI audit #16: digits and one decimal point only.
              inputFormatters: Validators.moneyFormatters,
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
                    : 'Event date: ${Formatters.date(_selectedEventDate!)}',
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
                    Formatters.peso(item.price), // "₱3,500.00" (#23)
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

              // UI audit #5: show the real filter panel (type, age group,
              // size, max price, event date). It used to show a leftover
              // placeholder card, so no filter could be reached.
              if (_showFilters) _buildFilters(),

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
