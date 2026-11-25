// Staff calendar (Calendar tab).
//
// * table_calendar with a Month / Week toggle.
// * Each day cell shows its date and a pill with how many bookings fall on
//   it (pick-up to return). Days where two blocking bookings hold the same
//   item are marked red (conflict).
// * Color legend, plus a filter: all / item types, and one item.
// * Tapping a day lists its bookings below the calendar (phones) or in a
//   side panel (wide screens, >= 900 px). Tapping a booking opens
//   /shop/bookings/:bookingId by path (no shop_bookings import).
// * Data is loaded per month (CalendarRules.loadRange) when the visible
//   month changes; the filter is applied in Dart.
//
// Calendar design (look only; data, rules and handlers unchanged):
// * Filters sit on the page as white rounded controls: Month / Week
//   (chosen = solid maroon), the categories (chosen = light pink) and a
//   bordered "All items" dropdown.
// * The calendar is one white card: a header with the month name and
//   previous / next buttons, a shaded weekday row, tall bordered day cells
//   (number in a circle, booking-count pill), the selected day tinted with
//   a solid maroon number, and a dot legend at the bottom (H1, H4, H6).
// * Phones (< 600 px card width) use shorter cells and show only the count
//   in the pill, so seven columns still fit.
// * The day panel is a white card with the date, the number of bookings
//   and the booking cards (H1).
//
// OWNER: Member 3.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/empty_view.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/list_skeleton.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_booking.dart';
import 'package:orange150_rental/features/shop_calendar/models/calendar_rules.dart';
import 'package:orange150_rental/features/shop_calendar/services/shop_calendar_service.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/calendar_segment_group.dart';
import 'package:orange150_rental/features/shop_calendar/widgets/day_booking_tile.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Colors from the calendar design, kept in one place.
class _CalColors {
  static const cardBorder = Color(0xFFE9E3E5);
  static const gridLine = Color(0xFFEEE8EA);
  static const buttonBorder = Color(0xFFE7E2E3);
  static const weekdayBg = Color(0xFFFDFAFB);
  static const selectedBg = Color(0xFFFAF0F2);
  static const pillBg = Color(0xFFF1E4E7);
  static const conflictBg = Color(0xFFF8E1E2);
  static const textMain = Color(0xFF292126);
  static const textSoft = Color(0xFF525252);

  // Legend dots (status order as staff see it).
  static const pending = Color(0xFFA17247);
  static const reserved = Color(0xFF7B1F2B);
  static const rentedOut = Color(0xFF66547E);
  static const returned = Color(0xFF537B69);
  static const conflict = Color(0xFFA43D42);
}

/// The staff "Calendar" screen.
class ShopCalendarScreen extends StatefulWidget {
  /// Creates the screen.
  const ShopCalendarScreen({super.key});

  /// Content width from which the day list becomes a side panel.
  static const double sidePanelBreakpoint = 900;

  /// Card width below which the compact day cells are used.
  static const double compactCellBreakpoint = 600;

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

  /// Given by table_calendar; used by our own previous / next buttons.
  PageController? _pageController;

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

  /// The calendar moved to another week or month. setState so the header
  /// shows the new month name.
  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    final month = DateTime.utc(focusedDay.year, focusedDay.month);
    if (month != _loadedMonth) _loadMonth(focusedDay);
  }

  // ---------------------------------------------------------------------------
  // Filter
  // ---------------------------------------------------------------------------

  /// All / one item type. Clears the item if it is not of that type.
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

  /// Jumps the calendar to today and selects it.
  void _goToToday() {
    final today = CalendarRules.dayKey(DateTime.now());
    setState(() => _selectedDay = today);
    _onPageChanged(today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blush,
      appBar: BrandAppBar(
        // Staff header: dark maroon, as on the Dashboard.
        backgroundColor: AppColors.maroonDeep,
        showLogo: false, // no hanger mark on staff headers
        titleSpacing: 40, // same title position as the Dashboard
        title: 'Calendar',
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
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
            // Filters straight on the page, with space above them.
            Padding(
              padding: EdgeInsets.only(top: wide ? 16 : 4, bottom: 16),
              child: _filterBar(),
            ),
            _calendarCard(),
          ];
          final day = _dayPanelCard();

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(32, 16, 16, 32),
                    children: top,
                  ),
                ),
                SizedBox(
                  width: 440,
                  child: ListView(
                    // Lines up with the calendar card, below the filters.
                    padding: const EdgeInsets.fromLTRB(0, 92, 32, 32),
                    children: [day],
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [...top, const SizedBox(height: 12), day],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filters (unchanged values and handlers)
  // ---------------------------------------------------------------------------

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
        // View: Month / Week (chosen = solid maroon).
        CalendarSegmentGroup<CalendarFormat>(
          options: const [
            (CalendarFormat.month, 'Month'),
            (CalendarFormat.week, 'Week'),
          ],
          selected: _format,
          onSelected: (format) => setState(() => _format = format),
        ),
        // Category filter: All plus every item type, chosen = light pink.
        // Scrolls sideways on narrow phones.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CalendarSegmentGroup<ItemType?>(
            style: SegmentStyle.tint,
            options: [
              for (final type in <ItemType?>[null, ...ItemType.values])
                (type, type?.label ?? 'All'),
            ],
            selected: _filter.type,
            onSelected: _setType,
          ),
        ),
        // One item: a white bordered dropdown.
        _itemPicker(itemsForType, selectedItem),
      ],
    );
  }

  /// The item dropdown in a white bordered box. Announced as "Item" so
  /// screen readers know what it filters.
  Widget _itemPicker(
    List<CalendarItem> itemsForType,
    CalendarItem? selectedItem,
  ) {
    return Semantics(
      label: 'Item',
      child: Container(
        width: 240,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: 16, right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineSoft, width: 0.8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedItem?.id,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnSoft,
            ),
            style: const TextStyle(color: AppColors.textOnSoft, fontSize: 14),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar card
  // ---------------------------------------------------------------------------

  /// White card: month header, the calendar grid and the legend.
  Widget _calendarCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CalColors.cardBorder, width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < ShopCalendarScreen.compactCellBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _calendarHeader(compact),
              // Thin bar while another month loads (H1).
              if (_loading && _loadedMonth != null)
                const LinearProgressIndicator(minHeight: 2),
              _calendar(compact),
              _legend(),
            ],
          );
        },
      ),
    );
  }

  /// Month name with previous / next buttons (replaces table_calendar's
  /// own header).
  Widget _calendarHeader(bool compact) {
    final isWeek = _format == CalendarFormat.week;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _CalColors.gridLine, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(
                  color: _CalColors.textMain,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          _navButton(
            icon: Icons.chevron_left,
            tooltip: isWeek ? 'Previous week' : 'Previous month',
            onPressed: () => _pageController?.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(width: 8),
          _navButton(
            icon: Icons.chevron_right,
            tooltip: isWeek ? 'Next week' : 'Next month',
            onPressed: () => _pageController?.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  /// A white bordered 44 px square button (design), 48 px tap target.
  Widget _navButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: _CalColors.textMain),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _CalColors.buttonBorder, width: 0.8),
        ),
      ),
    );
  }

  /// The table_calendar grid with our own day cells.
  Widget _calendar(bool compact) {
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
      headerVisible: false, // our own header above
      daysOfWeekHeight: 44,
      // 72 on phones (was 60) so the status dots fit under the count pill.
      rowHeight: compact ? 72 : 96,
      onCalendarCreated: (controller) => _pageController = controller,
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        cellMargin: EdgeInsets.zero,
        cellPadding: EdgeInsets.zero,
        tablePadding: EdgeInsets.zero,
        // Grid lines between every cell (design).
        tableBorder: TableBorder(
          horizontalInside: BorderSide(color: _CalColors.gridLine, width: 0.8),
          verticalInside: BorderSide(color: _CalColors.gridLine, width: 0.8),
          bottom: BorderSide(color: _CalColors.gridLine, width: 0.8),
        ),
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
        // Shaded weekday row: Sun, Mon, ...
        dowBuilder: (context, day) => Container(
          color: _CalColors.weekdayBg,
          alignment: Alignment.center,
          child: Text(
            DateFormat.E().format(day),
            style: const TextStyle(color: _CalColors.textSoft, fontSize: 12),
          ),
        ),
        defaultBuilder: (context, day, _) => _dayCell(day, compact: compact),
        todayBuilder: (context, day, _) =>
            _dayCell(day, compact: compact, isToday: true),
        selectedBuilder: (context, day, _) =>
            _dayCell(day, compact: compact, isSelected: true),
        outsideBuilder: (context, day, _) =>
            _dayCell(day, compact: compact, isOutside: true),
        // The status dots are drawn inside _dayCell, so no extra markers.
        markerBuilder: (context, day, events) => const SizedBox.shrink(),
      ),
    );
  }

  /// One day cell: the date in a circle and, if there are bookings, a pill
  /// with the count. Selected = tinted cell with a solid maroon circle.
  /// Conflict = red ring and a red pill (H1, H5).
  Widget _dayCell(
    DateTime day, {
    required bool compact,
    bool isSelected = false,
    bool isToday = false,
    bool isOutside = false,
  }) {
    final key = CalendarRules.dayKey(day);
    final count = _byDay[key]?.length ?? 0;
    final conflict = _hasVisibleConflict(day);

    // Circle around the date.
    Color? circleFill;
    Color numberColor = isOutside
        ? _CalColors.textSoft.withValues(alpha: 0.5)
        : _CalColors.textMain;
    BoxBorder? circleBorder;
    if (isSelected) {
      circleFill = AppColors.maroon;
      numberColor = Colors.white;
    } else if (conflict) {
      circleBorder = Border.all(color: _CalColors.conflict, width: 2);
      numberColor = _CalColors.conflict;
    } else if (isToday) {
      circleFill = AppColors.gold.withValues(alpha: 0.35);
    }

    final countLabel = compact
        ? '$count'
        : '$count booking${count == 1 ? '' : 's'}';

    return Semantics(
      label:
          '${DateFormat('MMMM d').format(day)}, '
          '${count == 0 ? 'no bookings' : '$count booking${count == 1 ? '' : 's'}'}'
          '${conflict ? ', conflict' : ''}',
      selected: isSelected,
      child: Container(
        color: isSelected ? _CalColors.selectedBg : Colors.white,
        padding: EdgeInsets.all(compact ? 4 : 12),
        alignment: compact ? Alignment.topCenter : Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleFill,
                shape: BoxShape.circle,
                border: circleBorder,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: numberColor,
                  fontSize: 14,
                  fontWeight: conflict || isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (count > 0) ...[
              SizedBox(height: compact ? 4 : 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: conflict ? _CalColors.conflictBg : _CalColors.pillBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    countLabel,
                    style: TextStyle(
                      color: conflict ? _CalColors.conflict : AppColors.maroon,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Status dots: one per status in its legend color, so staff
              // can see the mix of statuses at a glance (H1).
              SizedBox(height: compact ? 3 : 6),
              _statusDots(_byDay[key]!, compact: compact),
            ],
          ],
        ),
      ),
    );
  }

  /// Legend color for a booking's status (same colors as [_legend]).
  /// Cancelled / expired are not shown on the calendar; grey just in case.
  static Color _statusColor(BookingStatus status) => switch (status) {
    BookingStatus.pending => _CalColors.pending,
    BookingStatus.reserved => _CalColors.reserved,
    BookingStatus.rentedOut => _CalColors.rentedOut,
    BookingStatus.returned => _CalColors.returned,
    _ => _CalColors.textSoft,
  };

  /// Row of colored dots under a date: ONE dot per status present on that
  /// day (two pendings = one pending dot), in legend order. With at most
  /// four statuses the row always fits, so no "+N" is needed.
  /// The cell's Semantics label already reads the count, so the dots are
  /// decorative for screen readers.
  Widget _statusDots(List<CalendarBooking> bookings, {required bool compact}) {
    final present = {for (final b in bookings) CalendarRules.displayStatus(b)};
    // Legend order first, then anything else (e.g. cancelled) at the end.
    final statuses = [
      ...CalendarRules.shownStatuses.where(present.contains),
      ...present.where((s) => !CalendarRules.shownStatuses.contains(s)),
    ];
    final size = compact ? 6.0 : 8.0;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in statuses)
            Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status),
              ),
            ),
        ],
      ),
    );
  }

  /// Dot legend under the grid (design).
  Widget _legend() {
    const entries = [
      (_CalColors.pending, 'Pending'),
      (_CalColors.reserved, 'Reserved'),
      (_CalColors.rentedOut, 'Rented Out'),
      (_CalColors.returned, 'Returned'),
      (_CalColors.conflict, 'Conflict'),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final (color, label) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _CalColors.textSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
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

  // ---------------------------------------------------------------------------
  // Day panel card
  // ---------------------------------------------------------------------------

  /// White card with the selected day's heading and bookings.
  Widget _dayPanelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(2),
          bottom: Radius.circular(16),
        ),
        border: Border.all(color: _CalColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _dayPanel(),
      ),
    );
  }

  /// Heading: icon, "November 24" and the number of bookings.
  Widget _dayHeading(int? count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_note, size: 24, color: AppColors.maroon),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    DateFormat('MMMM d').format(_selectedDay),
                    style: const TextStyle(
                      color: _CalColors.textMain,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (count != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$count booking${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: _CalColors.textSoft,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The selected day's bookings, with loading / error / empty states.
  List<Widget> _dayPanel() {
    if (_loading && _loadedMonth == null) {
      // Booking-shaped skeleton cards instead of a spinner (H1).
      return [
        _dayHeading(null),
        const ListSkeleton(
          count: 2,
          showPhoto: false,
          padding: EdgeInsets.zero,
        ),
      ];
    }
    if (_error != null) {
      return [
        _dayHeading(null),
        ErrorView(message: _error!, onRetry: () => _loadMonth(_focusedDay)),
      ];
    }

    final bookings = _byDay[_selectedDay] ?? const <CalendarBooking>[];
    final conflictIds = _conflicts[_selectedDay] ?? const <String>{};
    if (bookings.isEmpty) {
      return [
        _dayHeading(0),
        EmptyView(
          icon: Icons.event_available_outlined,
          message: _filter.isEmpty
              ? 'No bookings on this day.'
              : 'No bookings on this day for this filter.',
        ),
      ];
    }
    return [
      _dayHeading(bookings.length),
      for (final booking in bookings)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DayBookingTile(
            booking: booking,
            day: _selectedDay,
            inConflict: conflictIds.contains(booking.booking.id),
            onTap: () => _openBooking(booking.booking.id),
          ),
        ),
    ];
  }
}
