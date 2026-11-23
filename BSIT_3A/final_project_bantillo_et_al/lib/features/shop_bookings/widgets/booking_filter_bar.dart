// Search field, status chips and event-date filter shown above the staff
// bookings list. It only reports changes through callbacks; the list
// screen owns the filter and reloads the data.
//
// OWNER: Member 3.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/features/shop_bookings/models/shop_booking_filter.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// Filter controls for the bookings list.
class BookingFilterBar extends StatefulWidget {
  /// Creates the bar showing [filter]; [onChanged] gets every new filter.
  const BookingFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  /// The current filter.
  final ShopBookingFilter filter;

  /// Called with the new filter when the user changes something.
  final ValueChanged<ShopBookingFilter> onChanged;

  @override
  State<BookingFilterBar> createState() => _BookingFilterBarState();
}

class _BookingFilterBarState extends State<BookingFilterBar> {
  late final TextEditingController _search = TextEditingController(
    text: widget.filter.query,
  );

  /// Waits a moment after typing so we do not query on every key press.
  Timer? _debounce;

  @override
  void didUpdateWidget(BookingFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text box in sync when the filter comes from a new URL.
    if (widget.filter.query != _search.text.trim() &&
        widget.filter.query != oldWidget.filter.query) {
      _search.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Sends the search text 400 ms after the user stops typing.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(widget.filter.copyWith(query: text.trim()));
    });
  }

  /// Sends the search text right away (Enter key).
  void _submitSearch(String text) {
    _debounce?.cancel();
    widget.onChanged(widget.filter.copyWith(query: text.trim()));
  }

  /// Clears the search box.
  void _clearSearch() {
    _search.clear();
    _submitSearch('');
  }

  /// Opens the date range picker for the event date.
  Future<void> _pickDates() async {
    final now = DateTime.now();
    final filter = widget.filter;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: filter.hasDateRange
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
      helpText: 'Filter by event date',
    );
    if (range == null) return;
    widget.onChanged(filter.copyWith(from: range.start, to: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Search reference no. or customer name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _search,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
        ),

        // Status chips, scrollable sideways on narrow phones.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _chip(
                label: 'All',
                selected: filter.status == null,
                onSelected: () =>
                    widget.onChanged(filter.copyWith(clearStatus: true)),
              ),
              for (final status in BookingStatus.values)
                _chip(
                  label: status.label,
                  selected: filter.status == status,
                  onSelected: () =>
                      widget.onChanged(filter.copyWith(status: status)),
                ),
            ],
          ),
        ),

        // Event date filter.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: _pickDates,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    filter.hasDateRange
                        ? Formatters.dateRange(filter.from!, filter.to!)
                        : 'Any event date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (filter.hasDateRange)
                IconButton(
                  tooltip: 'Clear date filter',
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      widget.onChanged(filter.copyWith(clearDates: true)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// One status chip.
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
