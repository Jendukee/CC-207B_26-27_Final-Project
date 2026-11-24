// Filter bottom sheet for Browse (customer redesign, Phase 1), like the
// filter panel of a shopping app: chip groups for type, age group, size
// and price range, an event date picker, and "Reset" / "Apply" pinned at
// the bottom. Nothing changes on Browse until Apply is pressed; closing the
// sheet keeps the old filters.
//
// Usage:
//   final result = await showFilterSheet(context, current: filter, sizes: s);
//   if (result != null) setState(() => filter = result);
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/catalog/models/catalog_rules.dart';
import 'package:orange150_rental/features/catalog/models/item_filter.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Opens the sheet and returns the new filter, or null if closed.
Future<ItemFilter?> showFilterSheet(
  BuildContext context, {
  required ItemFilter current,
  required List<String> sizes,
}) {
  return showModalBottomSheet<ItemFilter>(
    context: context,
    isScrollControlled: true, // lets the sheet grow to 90% of the screen
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: current, sizes: sizes),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.sizes});

  final ItemFilter initial;
  final List<String> sizes;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  /// The draft filter; only returned when Apply is pressed.
  late ItemFilter _draft = widget.initial;

  /// Event date picker (today onwards).
  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.eventDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Show items free on this event date',
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(eventDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = PriceRange.of(_draft);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Filters', style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                _group<ItemType>(
                  title: 'Type',
                  options: ItemType.values,
                  labelOf: (t) => t.label,
                  selected: _draft.type,
                  onChanged: (t) => setState(
                    () => _draft = t == null
                        ? _draft.copyWith(clearType: true)
                        : _draft.copyWith(type: t),
                  ),
                ),
                _group<AgeGroup>(
                  title: 'Age group',
                  options: AgeGroup.values,
                  labelOf: (a) => a.label,
                  selected: _draft.ageGroup,
                  onChanged: (a) => setState(
                    () => _draft = a == null
                        ? _draft.copyWith(clearAgeGroup: true)
                        : _draft.copyWith(ageGroup: a),
                  ),
                ),
                if (widget.sizes.isNotEmpty)
                  _group<String>(
                    title: 'Size',
                    options: widget.sizes,
                    labelOf: (s) => s,
                    selected: _draft.size,
                    onChanged: (s) => setState(
                      () => _draft = s == null
                          ? _draft.copyWith(clearSize: true)
                          : _draft.copyWith(size: s),
                    ),
                  ),
                _group<PriceRange>(
                  title: 'Price',
                  options: PriceRange.values,
                  labelOf: (p) => p.label,
                  selected: price,
                  onChanged: (p) => setState(
                    () => _draft = p == null
                        ? _draft.copyWith(clearPrice: true)
                        // Set both ends (clear first so a null end stays null).
                        : _draft
                              .copyWith(clearPrice: true)
                              .copyWith(minPrice: p.min, maxPrice: p.max),
                  ),
                ),
                Text('Event date', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _draft.eventDate == null
                              ? 'Any date'
                              : Formatters.date(_draft.eventDate!),
                        ),
                      ),
                    ),
                    if (_draft.eventDate != null)
                      IconButton(
                        tooltip: 'Remove event date',
                        onPressed: () => setState(
                          () => _draft = _draft.copyWith(clearEventDate: true),
                        ),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Pinned at the bottom of the sheet.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _draft = _draft.reset()),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A titled group of single-choice chips with an "All" chip first.
  Widget _group<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
              ),
              for (final option in options)
                ChoiceChip(
                  label: Text(labelOf(option)),
                  selected: selected == option,
                  onSelected: (_) => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
