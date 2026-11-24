// Reservation step 1: choose an event date and verify the full rental period.
//
// UI audit changes:
//   * #13 dates whose pick-up, event or return day is already booked are
//     DISABLED in the date picker (blocked days are loaded first). If the
//     chosen date was just taken, the closest free dates are offered as
//     one-tap suggestions.
//   * #8  the earliest event date is 2 days away (payment deadline rule).
//   * #12 friendly errors, with Retry when loading fails.
//   * #23 dates use the shared Formatters ("Dec 24, 2026").
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/utils/error_messages.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/utils/event_date_rules.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Choose the event date for the selected item.
class ReserveDatesScreen extends StatefulWidget {
  /// Creates the screen for [itemId].
  const ReserveDatesScreen({super.key, required this.itemId});

  /// Path parameter from the route.
  final String itemId;

  @override
  State<ReserveDatesScreen> createState() => _ReserveDatesScreenState();
}

/// The item plus its blocked days, loaded together.
class _DatesData {
  const _DatesData(this.item, this.blockedDays);

  final Item item;

  /// Null when the blocked days could not be loaded: the picker then
  /// allows every date and the date is checked after it is chosen.
  final Set<DateTime>? blockedDays;
}

class _ReserveDatesScreenState extends State<ReserveDatesScreen> {
  final ReservationService _service = ReservationService();
  late Future<_DatesData> _dataFuture;
  DateTime? _eventDate;
  bool? _isAvailable;
  bool _checkingAvailability = false;

  /// Free dates offered when the chosen one is taken.
  List<DateTime> _suggestions = const [];

  /// First and last date the picker offers.
  late final DateTime _earliest = ReservationService.earliestEventDate();
  late final DateTime _latest = DateTime(
    _earliest.year + 2,
    _earliest.month,
    _earliest.day,
  );

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  /// Loads the item and the blocked days for the whole picker range.
  Future<_DatesData> _load() async {
    final item = await _service.getItem(widget.itemId);
    Set<DateTime>? blocked;
    try {
      blocked = await _service.blockedDays(
        itemId: widget.itemId,
        // One extra day each side: pick-up and return days count too.
        from: _earliest.subtract(const Duration(days: 1)),
        to: _latest.add(const Duration(days: 1)),
      );
    } catch (_) {
      blocked = null; // still usable; the date is checked after picking
    }
    return _DatesData(item, blocked);
  }

  /// Retry after a failed load.
  void _retry() => setState(() => _dataFuture = _load());

  /// Opens the date picker with booked dates disabled.
  Future<void> _chooseDate(_DatesData data) async {
    final blocked = data.blockedDays;
    // initialDate must itself be selectable, or the picker throws.
    final first = blocked == null
        ? _earliest
        : EventDateRules.firstFree(_earliest, _latest, blocked);
    if (first == null) {
      _showSnack('This item is fully booked for the next 2 years.');
      return;
    }
    final current = _eventDate;
    final initial =
        current != null &&
            (blocked == null || EventDateRules.isFree(current, blocked))
        ? current
        : first;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _earliest,
      lastDate: _latest,
      helpText: 'Choose the event date',
      // Greyed-out days: pick-up, event or return day already booked.
      selectableDayPredicate: blocked == null
          ? null
          : (day) => EventDateRules.isFree(day, blocked),
    );
    if (selectedDate == null || !mounted) return;
    await _checkDate(data.item, selectedDate);
  }

  /// Double-checks [date] with the server (someone may have just booked
  /// it) and offers the closest free dates if it is taken.
  Future<void> _checkDate(Item item, DateTime date) async {
    setState(() {
      _eventDate = date;
      _isAvailable = null;
      _suggestions = const [];
      _checkingAvailability = true;
    });

    try {
      final available =
          item.condition == ItemCondition.available &&
          await _service.isItemAvailable(
            itemId: widget.itemId,
            eventDate: date,
          );
      var suggestions = const <DateTime>[];
      if (!available) {
        // Reload the blocked days so the suggestions are up to date.
        final blocked = await _service.blockedDays(
          itemId: widget.itemId,
          from: _earliest.subtract(const Duration(days: 1)),
          to: _latest.add(const Duration(days: 1)),
        );
        suggestions = EventDateRules.nearestFree(
          date,
          blocked,
          earliest: _earliest,
          latest: _latest,
        );
      }
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _suggestions = suggestions;
        _checkingAvailability = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingAvailability = false);
      _showSnack(
        friendlyErrorMessage(
          error,
          fallback: 'Could not check availability. Please try again.',
        ),
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _continue() {
    final eventDate = _eventDate;
    if (eventDate == null || _isAvailable != true) return;
    context.pushNamed(
      RouteNames.reserveMeasurements,
      pathParameters: {'itemId': widget.itemId},
      extra: ReservationDraft(itemId: widget.itemId, eventDate: eventDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Event Date')),
      body: FutureBuilder<_DatesData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading available dates...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: friendlyErrorMessage(
                snapshot.error!,
                fallback: 'Could not load this item. Please try again.',
              ),
              onRetry: _retry,
            );
          }
          final data = snapshot.requireData;
          final item = data.item;
          final event = _eventDate;
          return Column(
            children: [
              const ReservationStepIndicator(step: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your event date, at least 2 days from today. '
                      'Pickup is the day before, and return is the day after. '
                      'Dates that are already booked are greyed out.',
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rental period'),
                            const SizedBox(height: 8),
                            Text(
                              event == null
                                  ? 'Pickup: —\nEvent: —\nReturn: —'
                                  : 'Pickup: ${Formatters.date(event.subtract(const Duration(days: 1)))}\n'
                                        'Event: ${Formatters.date(event)}\n'
                                        'Return: ${Formatters.date(event.add(const Duration(days: 1)))}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed:
                          item.condition == ItemCondition.available &&
                              !_checkingAvailability
                          ? () => _chooseDate(data)
                          : null,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        event == null
                            ? 'Select event date'
                            : Formatters.date(event),
                      ),
                    ),
                    if (_checkingAvailability) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Checking all three rental dates…'),
                    ] else if (item.condition != ItemCondition.available) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'This item is not currently available to rent.',
                      ),
                    ] else if (_isAvailable == true) ...[
                      const SizedBox(height: 12),
                      const Text('Available for the selected rental dates.'),
                    ] else if (_isAvailable == false) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Unavailable: at least one of the pickup, event, or '
                        'return dates was just booked.'
                        '${_suggestions.isEmpty ? ' Choose another date.' : ' These dates are free:'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      // One tap picks a suggested free date.
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final date in _suggestions)
                              ActionChip(
                                avatar: const Icon(Icons.event_available),
                                label: Text(Formatters.date(date)),
                                onPressed: () => _checkDate(item, date),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isAvailable == true ? _continue : null,
                      child: const Text('Continue to measurements'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
