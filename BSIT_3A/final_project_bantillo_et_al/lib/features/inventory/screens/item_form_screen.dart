// Staff form to add or edit a rentable item (name, type, age group, size,
// price, condition, description, inclusions, photos).
//
// UI audit changes: a failed save keeps the form (#11); after the first
// successful insert the form switches to edit mode, so pressing Save again
// after an error updates the item instead of creating a duplicate; type and
// age group use SegmentedButtons (#21); the price accepts numbers only
// (#16); retiring an item asks for confirmation (#18); live validation
// (#26), FilledButton (#27), shared Loading/Error views (#28), inclusions
// as chips and a discard-changes warning (#40).
//
// OWNER: Member 1.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/validators.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
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

  /// Text box for typing ONE new inclusion (added as a chip, UI audit #40).
  final _inclusionsController = TextEditingController();

  /// The item's inclusions, shown as chips with a remove button.
  final List<String> _inclusions = [];

  /// True once anything was changed; Back then asks before discarding
  /// (UI audit #40).
  bool _dirty = false;

  ItemType _type = ItemType.gown;
  AgeGroup _ageGroup = AgeGroup.adult;
  ItemCondition _condition = ItemCondition.available;

  List<String> _existingPhotoUrls = [];
  final List<XFile> _newPhotos = [];

  bool _isLoading = false;
  bool _isSaving = false;

  /// Id of the item being edited. Starts as widget.itemId (null for a new
  /// item) and is set after the first successful insert (duplicate fix).
  late String? _itemId = widget.itemId;

  /// True once the item exists in the database: Save then updates it.
  bool get _isEditing => _itemId != null;

  /// Condition when the form opened, to know if staff are retiring it.
  ItemCondition _originalCondition = ItemCondition.available;

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
        _inclusions
          ..clear()
          ..addAll(item.inclusions);

        _type = item.type;
        _ageGroup = item.ageGroup;
        _condition = item.condition;
        _originalCondition = item.condition;
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
        _dirty = true;
      });
    } catch (e) {
      if (!mounted) return;

      // UI audit #12: no raw exception text.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              e,
              fallback: 'Could not open your photos. Please try again.',
            ),
          ),
        ),
      );
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

  /// Adds the typed inclusion as a chip (ignores blanks and duplicates).
  void _addInclusion() {
    final value = _inclusionsController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      final exists = _inclusions.any(
        (i) => i.toLowerCase() == value.toLowerCase(),
      );
      if (!exists) _inclusions.add(value);
      _inclusionsController.clear();
      _dirty = true;
    });
  }

  /// The inclusions to save, including text typed but not yet added.
  List<String> _parseInclusions() {
    final pending = _inclusionsController.text.trim();
    return [
      ..._inclusions,
      if (pending.isNotEmpty &&
          !_inclusions.any((i) => i.toLowerCase() == pending.toLowerCase()))
        pending,
    ];
  }

  /// Back with unsaved changes: ask before throwing them away.
  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this item have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _dirty = false;
      Navigator.of(context).pop();
    }
  }

  /// UI audit #18: asks before retiring, because a retired item leaves the
  /// catalog. Returns true when it is OK to save.
  Future<bool> _confirmRetireIfNeeded() async {
    final retiring =
        _condition == ItemCondition.retired &&
        _originalCondition != ItemCondition.retired;
    if (!retiring) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retire this item?'),
        content: const Text(
          'Retired items are hidden from the catalog and cannot be '
          'reserved. You can bring it back later by changing its condition.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retire item'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _confirmRetireIfNeeded() || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Was this a brand-new item when Save was pressed? (for the message)
    final wasNew = !_isEditing;

    try {
      final item = Item(
        id: _itemId ?? '',
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

      if (_isEditing) {
        savedItem = await _service.updateItem(item);
      } else {
        savedItem = await _service.createItem(item);
        // Duplicate fix: remember the new id right away. If a later step
        // (photo upload) fails and staff press Save again, the form is now
        // in edit mode and UPDATES this item instead of inserting a copy.
        _itemId = savedItem.id;
      }

      // Upload new photos one by one. Each uploaded photo moves to
      // _existingPhotoUrls at once, so a retry never uploads it twice.
      for (final photo in List<XFile>.of(_newPhotos)) {
        final Uint8List bytes = await photo.readAsBytes();

        final url = await _service.uploadPhoto(
          itemId: savedItem.id,
          bytes: bytes,
          fileName: photo.name,
        );

        _existingPhotoUrls.add(url);
        _newPhotos.remove(photo);
      }

      // Save the final photo list.
      final updatedItem = Item(
        id: savedItem.id,
        name: item.name,
        type: item.type,
        ageGroup: item.ageGroup,
        size: item.size,
        price: item.price,
        description: item.description,
        inclusions: item.inclusions,
        photoUrls: List<String>.of(_existingPhotoUrls),
        condition: item.condition,
        createdAt: savedItem.createdAt,
      );
      savedItem = await _service.updateItem(updatedItem);
      _originalCondition = savedItem.condition;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasNew ? 'Item added successfully!' : 'Item updated successfully!',
          ),
        ),
      );

      _dirty = false; // saved: leaving no longer needs a warning
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      // Shown above the Save button; the form keeps the user's edits.
      // setState also refreshes the photo list and the title ("Edit
      // Item" once a new item was saved).
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

  /// A label above a SegmentedButton with one segment per value.
  Widget _segmentedField<T>({
    required String label,
    required List<T> values,
    required String Function(T value) labelOf,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final value in values)
              ButtonSegment<T>(value: value, label: Text(labelOf(value))),
          ],
          selected: {selected},
          onSelectionChanged: _isSaving
              ? null
              : (selection) => onChanged(selection.first),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      // Any typed change marks the form as changed (discard warning).
      onChanged: () => _dirty = true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            // UI audit #26: errors show once the field was touched.
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
          // UI audit #21: exactly one of two options -> SegmentedButton,
          // so both choices are always visible (was a dropdown).
          _segmentedField<ItemType>(
            label: 'Item Type *',
            values: ItemType.values,
            labelOf: (type) => type.label,
            selected: _type,
            onChanged: (type) => setState(() => _type = type),
          ),
          const SizedBox(height: 16),
          _segmentedField<AgeGroup>(
            label: 'Age Group *',
            values: AgeGroup.values,
            labelOf: (group) => group.label,
            selected: _ageGroup,
            onChanged: (group) => setState(() => _ageGroup = group),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sizeController,
            // UI audit #26: errors show once the field was touched.
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
            // UI audit #26: errors show once the field was touched.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // UI audit #16: digits and one decimal point (max 2 decimals).
            inputFormatters: Validators.moneyFormatters,
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
          // UI audit #40: inclusions as chips. Type one, press Add (or
          // Enter); remove one with its x.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inclusionsController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addInclusion(),
                  decoration: const InputDecoration(
                    labelText: 'Add an inclusion',
                    hintText: 'e.g. Veil',
                    helperText: 'Free accessories that come with the item.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _addInclusion,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          if (_inclusions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final inclusion in _inclusions)
                  InputChip(
                    label: Text(inclusion),
                    onDeleted: _isSaving
                        ? null
                        : () => setState(() {
                            _inclusions.remove(inclusion);
                            _dirty = true;
                          }),
                    deleteButtonTooltipMessage: 'Remove $inclusion',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _buildPhotoSection(),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          // UI audit #27: the app's primary button style (FilledButton).
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveItem,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            // Same discard check as Back.
            onPressed: _isSaving
                ? null
                : () =>
                      _dirty ? _confirmDiscard() : Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI audit #40: Back with unsaved changes asks first.
    return PopScope(
      canPop: !_dirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Item' : 'Add Item')),
        // UI audit #28: the shared loading and error (Retry) views.
        body: _isLoading
            ? const LoadingView(message: 'Loading item...')
            // Only a failed LOAD replaces the form; a failed save does not.
            : _loadError != null
            ? ErrorView(message: _loadError!, onRetry: _loadItem)
            : _buildForm(),
      ),
    );
  }
}
