// Reservation step 1: choose an event date and verify the full rental period.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reservation/models/reservation_draft.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/features/reservation/widgets/reservation_step_indicator.dart';
import 'package:orange150_rental/shared/models/item.dart';

/// Choose the event date for the selected item.
class ReserveDatesScreen extends StatefulWidget {
  const ReserveDatesScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ReserveDatesScreen> createState() => _ReserveDatesScreenState();
}

class _ReserveDatesScreenState extends State<ReserveDatesScreen> {
  final ReservationService _service = ReservationService();
  final DateFormat _dateFormat = DateFormat.yMMMMd();
  late final Future<Item> _itemFuture;
  DateTime? _eventDate;
  bool? _isAvailable;
  bool _checkingAvailability = false;

  @override
  void initState() {
    super.initState();
    _itemFuture = _service.getItem(widget.itemId);
  }

  Future<void> _chooseDate(Item item) async {
    final today = DateUtils.dateOnly(DateTime.now());
    // UI audit #8: earliest event is 2 days away, so pick-up is tomorrow
    // or later and the 48-hour payment deadline ends before pick-up day
    // (same rule as create_reservation in the database).
    final earliest = ReservationService.earliestEventDate(today);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? earliest,
      firstDate: earliest,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Choose the event date',
    );
    if (selectedDate == null || !mounted) return;

    setState(() {
      _eventDate = selectedDate;
      _isAvailable = null;
      _checkingAvailability = true;
    });

    try {
      final available =
          item.condition == ItemCondition.available &&
          await _service.isItemAvailable(
            itemId: widget.itemId,
            eventDate: selectedDate,
          );
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _checkingAvailability = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingAvailability = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check availability: $error')),
      );
    }
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
      body: FutureBuilder<Item>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: 'Could not load this item: ${snapshot.error}',
            );
          }
          final item = snapshot.requireData;
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
                    Text(
                      'Choose your event date, at least 2 days from today. '
                      'Pickup is the day before, and return is the day after.',
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
                              _eventDate == null
                                  ? 'Pickup: —\nEvent: —\nReturn: —'
                                  : 'Pickup: ${_dateFormat.format(_eventDate!.subtract(const Duration(days: 1)))}\n'
                                        'Event: ${_dateFormat.format(_eventDate!)}\n'
                                        'Return: ${_dateFormat.format(_eventDate!.add(const Duration(days: 1)))}',
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
                          ? () => _chooseDate(item)
                          : null,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _eventDate == null
                            ? 'Select event date'
                            : _dateFormat.format(_eventDate!),
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
                        'return dates is already booked. Choose another date.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}
