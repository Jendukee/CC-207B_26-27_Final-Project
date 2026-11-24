// Item details: photos, price, size, condition, description, inclusions
// and the Reserve button.
//
// OWNER: Member 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/catalog/services/catalog_service.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Displays the photos and information of one rentable item.
class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final CatalogService _catalogService = CatalogService();

  late Future<Item> _itemFuture;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() {
    _itemFuture = _catalogService.getItem(widget.itemId);
  }

  void _retryLoading() {
    setState(_loadItem);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: FutureBuilder<Item>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Unable to load item details.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryLoading,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildItemDetails(snapshot.data!);
        },
      ),
      bottomNavigationBar: FutureBuilder<Item>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const SizedBox.shrink();
          }

          final item = snapshot.data!;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.reserveDates,
                      pathParameters: {'itemId': item.id},
                    );
                  },
                  child: const Text(
                    'Reserve This Item',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemDetails(Item item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotos(item),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.type.label} • ${item.ageGroup.label}',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),

                // Rental price
                // UI audit #19: theme secondary text color (passes WCAG AA)
                // instead of Colors.grey (about 2.7:1 on white).
                Text(
                  'Rental Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.peso(item.price), // "₱3,500.00" (#23)
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Divider(height: 32),

                // Item information
                const Text(
                  'Item Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Size',
                  item.size.isEmpty ? 'Not specified' : item.size,
                ),
                _buildInfoRow('Type', item.type.label),
                _buildInfoRow('Age Group', item.ageGroup.label),
                _buildInfoRow('Condition', item.condition.label),

                const Divider(height: 32),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isEmpty
                      ? 'No description available.'
                      : item.description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),

                const SizedBox(height: 24),

                // Inclusions
                const Text(
                  'What\'s Included',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (item.inclusions.isEmpty)
                  const Text('No inclusions listed.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.inclusions.map((inclusion) {
                      return Chip(
                        label: Text(inclusion),
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotos(Item item) {
    if (item.photoUrls.isEmpty) {
      return Container(
        height: 280,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: Colors.grey,
        ),
      );
    }

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: PageView.builder(
        itemCount: item.photoUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            item.photoUrls[index],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
