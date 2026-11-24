// Staff form to add or edit a rentable item (name, type, age group, size,
// price, condition, description, inclusions, photos).
//
// OWNER: Member 1.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/features/inventory/services/inventory_service.dart';

/// Form for adding or editing a rentable item.
class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.itemId});

  final String? itemId;

  bool get isEditing => itemId != null;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final InventoryService _service = InventoryService();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _inclusionsController = TextEditingController();

  ItemType _type = ItemType.gown;
  AgeGroup _ageGroup = AgeGroup.adult;
  ItemCondition _condition = ItemCondition.available;

  List<String> _existingPhotoUrls = [];
  final List<XFile> _newPhotos = [];

  bool _isLoading = false;
  bool _isSaving = false;

  /// UI audit #11: two separate errors.
  /// [_loadError]: the item could not be loaded (full-screen error + Retry).
  /// [_errorMessage]: saving failed (shown above the Save button; the form
  /// and everything the user typed stay on screen).
  String? _loadError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadItem();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _inclusionsController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final items = await _service.listItems(includeRetired: true);
      final item = items.firstWhere((item) => item.id == widget.itemId);

      if (!mounted) return;

      setState(() {
        _nameController.text = item.name;
        _sizeController.text = item.size;
        _priceController.text = item.price.toString();
        _descriptionController.text = item.description;
        _inclusionsController.text = item.inclusions.join(', ');

        _type = item.type;
        _ageGroup = item.ageGroup;
        _condition = item.condition;
        _existingPhotoUrls = List<String>.from(item.photoUrls);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyErrorMessage(
          e,
          fallback: 'Could not load this item. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final photos = await _picker.pickMultiImage();

      if (!mounted || photos.isEmpty) return;

      setState(() {
        _newPhotos.addAll(photos);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to select photos: $e')));
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  List<String> _parseInclusions() {
    return _inclusionsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final item = Item(
        id: widget.itemId ?? '',
        name: _nameController.text.trim(),
        type: _type,
        ageGroup: _ageGroup,
        size: _sizeController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        inclusions: _parseInclusions(),
        photoUrls: _existingPhotoUrls,
        condition: _condition,
      );

      Item savedItem;

      if (widget.isEditing) {
        savedItem = await _service.updateItem(item);
      } else {
        savedItem = await _service.createItem(item);
      }

      final uploadedUrls = <String>[];

      for (final photo in _newPhotos) {
        final Uint8List bytes = await photo.readAsBytes();

        final url = await _service.uploadPhoto(
          itemId: savedItem.id,
          bytes: bytes,
          fileName: photo.name,
        );

        uploadedUrls.add(url);
      }

      if (_newPhotos.isNotEmpty || widget.isEditing) {
        final updatedItem = Item(
          id: savedItem.id,
          name: item.name,
          type: item.type,
          ageGroup: item.ageGroup,
          size: item.size,
          price: item.price,
          description: item.description,
          inclusions: item.inclusions,
          photoUrls: [..._existingPhotoUrls, ...uploadedUrls],
          condition: item.condition,
          createdAt: savedItem.createdAt,
        );

        savedItem = await _service.updateItem(updatedItem);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Item updated successfully!'
                : 'Item added successfully!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      // Shown above the Save button; the form keeps the user's edits.
      setState(() {
        _errorMessage = friendlyErrorMessage(
          e,
          fallback:
              'Could not save this item. Check your connection and '
              'press Save again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Select Photos'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._existingPhotoUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;

              return SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () => _removeExistingPhoto(index),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }),
            ..._newPhotos.asMap().entries.map((entry) {
              final index = entry.key;
              final photo = entry.value;

              return SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FutureBuilder<Uint8List>(
                        future: photo.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }

                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () => _removeNewPhoto(index),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              hintText: 'e.g. Ivory Ball Gown',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Item name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ItemType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Item Type',
              border: OutlineInputBorder(),
            ),
            items: ItemType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _type = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AgeGroup>(
            initialValue: _ageGroup,
            decoration: const InputDecoration(
              labelText: 'Age Group',
              border: OutlineInputBorder(),
            ),
            items: AgeGroup.values.map((group) {
              return DropdownMenuItem(value: group, child: Text(group.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _ageGroup = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sizeController,
            decoration: const InputDecoration(
              labelText: 'Size *',
              hintText: 'e.g. S, M, L, 8-10',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Size is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rental Price (PHP) *',
              prefixText: '₱ ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Rental price is required.';
              }

              final price = double.tryParse(value.trim());

              if (price == null || price <= 0) {
                return 'Enter a valid price greater than zero.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ItemCondition>(
            initialValue: _condition,
            decoration: const InputDecoration(
              labelText: 'Physical Condition',
              border: OutlineInputBorder(),
            ),
            items: ItemCondition.values.map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _condition = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the item...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _inclusionsController,
            decoration: const InputDecoration(
              labelText: 'Inclusions',
              hintText: 'Veil, Petticoat, Necklace',
              helperText: 'Separate inclusions with commas.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _buildPhotoSection(),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveItem,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : Text(widget.isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Item' : 'Add Item')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // Only a failed LOAD replaces the form; a failed save does not.
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadItem,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _buildForm(),
    );
  }
}
