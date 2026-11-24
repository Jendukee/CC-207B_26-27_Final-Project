// Confirmation for a successfully submitted pending booking.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/shared/models/booking.dart';

/// Shows the booking reference and dates after reservation submission.
class BookingConfirmationScreen extends StatelessWidget {
  BookingConfirmationScreen({super.key, required this.bookingId})
    : _bookingFuture = ReservationService().getBooking(bookingId);

  final String bookingId;
  final Future<Booking> _bookingFuture;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Submitted')),
      body: FutureBuilder<Booking>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load booking confirmation: ${snapshot.error}',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.goNamed(RouteNames.myBookings),
                      child: const Text('Go to My Bookings'),
                    ),
                  ],
                ),
              ),
            );
          }

          final booking = snapshot.requireData;
          final dueAmount = booking.paymentOption == PaymentOption.full
              ? booking.totalAmount
              : booking.totalAmount / 2;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Reservation request received',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your request is pending shop confirmation. Keep this reference '
                'number for your records.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference number',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SelectableText(
                        booking.referenceNo,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 28),
                      _ConfirmationRow(
                        label: 'Status',
                        value: booking.status.label,
                      ),
                      _ConfirmationRow(
                        label: 'Pickup',
                        value: dateFormat.format(booking.pickupDate),
                      ),
                      _ConfirmationRow(
                        label: 'Event',
                        value: dateFormat.format(booking.eventDate),
                      ),
                      _ConfirmationRow(
                        label: 'Return',
                        value: dateFormat.format(booking.returnDate),
                      ),
                      _ConfirmationRow(
                        label: 'Payment plan',
                        value: booking.paymentOption.label,
                      ),
                      _ConfirmationRow(
                        label: 'Planned payment',
                        value: currency.format(dueAmount),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No payment was collected in the app. Please wait for the shop '
                'to confirm your request and payment arrangements.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(RouteNames.myBookings),
                child: const Text('Go to My Bookings'),
              ),
              OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.browse),
                child: const Text('Continue browsing'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
