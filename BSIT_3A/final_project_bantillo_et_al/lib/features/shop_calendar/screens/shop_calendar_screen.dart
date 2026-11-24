// Staff calendar (Calendar tab).
//
// * table_calendar with a Month / Week toggle.
// * Each day shows one dot per booking (pick-up to return) in the
//   StatusChip color of its status. Days where two blocking bookings hold
//   the same item are marked red (conflict).
// * Color legend, plus a filter: all / gowns / suits, and one item.
// * Tapping a day lists its bookings below the calendar (phones) or in a
//   side panel (wide screens, >= 900 px). Tapping a booking opens
//   /shop/bookings/:bookingId by path (no shop_bookings import).
// * Data is loaded per month (CalendarRules.loadRange) when the visible
//   month changes; the filter is applied in Dart.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/features/shop_calendar/services/shop_calendar_service.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_legend.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/day_booking_tile.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/day_marker.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// The staff "Calendar" screen.
class ShopCalendarScreen extends StatefulWidget {
  /// Creates the screen.
  const ShopCalendarScreen({super.key});

  /// Content width from which the day list becomes a side panel.
  static const double sidePanelBreakpoint = 900;

  @override
  State<ShopCalendarScreen> createState() => _ShopCalendarScreenState();
}

class _ShopCalendarScreenState extends State<ShopCalendarScreen> {
  final ShopCalendarService _service = ShopCalendarService();

  static final DateTime _firstDay = DateTime.utc(2024, 1, 1);
  static final DateTime _lastDay = DateTime.utc(2030, 12, 31);

  // Calendar position.
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = CalendarRules.dayKey(DateTime.now());
  DateTime _selectedDay = CalendarRules.dayKey(DateTime.now());

  // Loaded data.
  List<CalendarBooking> _bookings = const [];
  List<CalendarItem> _items = const [];
  DateTime? _loadedMonth;
  bool _loading = true;
  String? _error;

  /// Increases with every load, so a slow old response cannot overwrite a
  /// newer month.
  int _requestId = 0;

  // Filter and the data derived from it (see _recompute).
  CalendarFilter _filter = const CalendarFilter();
  Map<DateTime, List<CalendarBooking>> _byDay = const {};
  Map<DateTime, Set<String>> _conflicts = const {};

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
    _loadItems();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Loads the bookings for the month containing [day].
  Future<void> _loadMonth(DateTime day) async {
    final requestId = ++_requestId;
    final month = DateTime.utc(day.year, day.month);
    final (from, to) = CalendarRules.loadRange(day);
    if (_loadedMonth != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final bookings = await _service.bookingsBetween(from, to);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _bookings = bookings;
        _loadedMonth = month;
        _loading = false;
        _recompute();
      });
    } on CalendarException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadedMonth = month;
      });
    }
  }

  /// Loads the item list for the filter. If it fails the filter just
  /// offers "All items"; the calendar still works.
  Future<void> _loadItems() async {
    try {
      final items = await _service.listItems();
      if (mounted) setState(() => _items = items);
    } on CalendarException {
      // Ignored on purpose (see above).
    }
  }

  /// Rebuilds the per-day map and conflicts from the bookings and filter.
  /// Call inside setState.
  void _recompute() {
    final visible = _bookings
        .where((b) => CalendarRules.matches(b, _filter))
        // Pending requests past their expiry hold nothing; hide them.
        .where((b) => CalendarRules.displayStatus(b) != BookingStatus.expired)
        .toList();
    _byDay = CalendarRules.byDay(visible);
    // Conflicts are checked on ALL loaded bookings, so a clash is still
    // found when only one side of it matches the filter.
    _conflicts = CalendarRules.conflicts(_bookings);
  }

  /// The calendar moved to another week or month.
  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    final month = DateTime.utc(focusedDay.year, focusedDay.month);
    if (month != _loadedMonth) _loadMonth(focusedDay);
  }

  // ---------------------------------------------------------------------------
  // Filter
  // ---------------------------------------------------------------------------

  /// All / gowns / suits. Clears the item if it is not of that type.
  void _setType(ItemType? type) {
    setState(() {
      final item = _itemById(_filter.itemId);
      final keepItem = item != null && (type == null || item.type == type);
      _filter = CalendarFilter(type: type, itemId: keepItem ? item.id : null);
      _recompute();
    });
  }

  /// One item, or null for any item.
  void _setItem(String? itemId) {
    setState(() {
      _filter = CalendarFilter(type: _filter.type, itemId: itemId);
      _recompute();
    });
  }

  CalendarItem? _itemById(String? id) {
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  /// Opens a booking in the Bookings tab, by path.
  void _openBooking(String id) => context.go('${RoutePaths.shopBookings}/$id');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'Calendar',
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = CalendarRules.dayKey(DateTime.now());
              setState(() {
                _selectedDay = today;
                _focusedDay = today;
              });
              _onPageChanged(today);
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMonth(_focusedDay),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= ShopCalendarScreen.sidePanelBreakpoint;
          final top = [
            _filterBar(),
            const SizedBox(height: 8),
            const CalendarLegend(),
            if (_loading && _loadedMonth != null) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            _calendar(),
          ];

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: top,
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _dayPanel(),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [...top, const Divider(height: 32), ..._dayPanel()],
          );
        },
      ),
    );
  }

  /// Month / week toggle, category and item filter.
  Widget _filterBar() {
    final itemsForType = _items
        .where((i) => _filter.type == null || i.type == _filter.type)
        .toList();
    final selectedItem = _itemById(_filter.itemId);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<CalendarFormat>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: CalendarFormat.month, label: Text('Month')),
            ButtonSegment(value: CalendarFormat.week, label: Text('Week')),
          ],
          selected: {_format},
          onSelectionChanged: (s) => setState(() => _format = s.first),
        ),
        // Category filter: All plus every item type (gown, long gown, suit,
        // bearer since migration 0010). Chips wrap on narrow phones.
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _filter.type == null,
              onSelected: (_) => _setType(null),
            ),
            for (final type in ItemType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _filter.type == type,
                onSelected: (_) => _setType(type),
              ),
          ],
        ),
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<String?>(
            // Rebuild when the type changes so the value stays valid.
            key: ValueKey(_filter.type),
            initialValue: selectedItem?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Item',
              prefixIcon: Icon(Icons.checkroom_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All items'),
              ),
              for (final item in itemsForType)
                DropdownMenuItem<String?>(
                  value: item.id,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _setItem,
          ),
        ),
      ],
    );
  }

  /// The table_calendar widget with status markers and conflict days.
  Widget _calendar() {
    final scheme = Theme.of(context).colorScheme;
    return TableCalendar<CalendarBooking>(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      calendarFormat: _format,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      startingDayOfWeek: StartingDayOfWeek.sunday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false, // our own Month / Week toggle
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
          color: AppColors.maroon,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: scheme.onSurface),
      ),
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      onDaySelected: (selected, focused) => setState(() {
        _selectedDay = CalendarRules.dayKey(selected);
        _focusedDay = focused;
      }),
      onFormatChanged: (format) => setState(() => _format = format),
      onPageChanged: _onPageChanged,
      eventLoader: (day) => _byDay[CalendarRules.dayKey(day)] ?? const [],
      calendarBuilders: CalendarBuilders<CalendarBooking>(
        // Red ring around days with a conflict.
        defaultBuilder: (context, day, focusedDay) {
          if (!_hasVisibleConflict(day)) return null;
          return Container(
            margin: const EdgeInsets.all(6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: calendarConflictColor, width: 2),
            ),
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: calendarConflictColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return DayMarker(
            bookings: events,
            hasConflict: _hasVisibleConflict(day),
          );
        },
      ),
    );
  }

  /// True if [day] has a conflict involving a booking that is shown.
  bool _hasVisibleConflict(DateTime day) {
    final key = CalendarRules.dayKey(day);
    final ids = _conflicts[key];
    if (ids == null) return false;
    final shown = _byDay[key] ?? const [];
    return shown.any((b) => ids.contains(b.booking.id));
  }

  /// The selected day's heading and bookings (with loading / error /
  /// empty states).
  List<Widget> _dayPanel() {
    final theme = Theme.of(context);
    final heading = Text(
      Formatters.date(_selectedDay),
      style: theme.textTheme.titleMedium,
    );

    if (_loading && _loadedMonth == null) {
      return [heading, const LoadingView(message: 'Loading bookings...')];
    }
    if (_error != null) {
      return [
        heading,
        ErrorView(message: _error!, onRetry: () => _loadMonth(_focusedDay)),
      ];
    }

    final bookings = _byDay[_selectedDay] ?? const <CalendarBooking>[];
    final conflictIds = _conflicts[_selectedDay] ?? const <String>{};
    if (bookings.isEmpty) {
      return [
        heading,
        EmptyView(
          icon: Icons.event_available_outlined,
          message: _filter.isEmpty
              ? 'No bookings on this day.'
              : 'No bookings on this day for this filter.',
        ),
      ];
    }
    return [
      heading,
      const SizedBox(height: 4),
      Text(
        '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall,
      ),
      for (final booking in bookings)
        DayBookingTile(
          booking: booking,
          day: _selectedDay,
          inConflict: conflictIds.contains(booking.booking.id),
          onTap: () => _openBooking(booking.booking.id),
        ),
    ];
  }
}
