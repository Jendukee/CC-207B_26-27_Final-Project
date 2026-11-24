// Customer booking details: items, dates, payments, balance and status.
// Allows cancelling a pending or reserved booking (with a confirm dialog).
//
// OWNER: Member 2.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/widgets/error_view.dart';

import 'package:orange150_rental/features/my_bookings/models/booking_details.dart';
import 'package:orange150_rental/features/my_bookings/services/my_bookings_service.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_formatters.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_status_badge.dart';
import 'package:orange150_rental/features/my_bookings/widgets/detail_section.dart';

class CustomerBookingDetailsScreen extends StatefulWidget {
  const CustomerBookingDetailsScreen({super.key, required this.bookingId});

  /// Path parameter from the route (see my_bookings_routes.dart).
  final String bookingId;

  @override
  State<CustomerBookingDetailsScreen> createState() =>
      _CustomerBookingDetailsScreenState();
}

class _CustomerBookingDetailsScreenState
    extends State<CustomerBookingDetailsScreen> {
  final _service = MyBookingsService();
  late Future<BookingDetails> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<BookingDetails> _load() async {
    final myBooking = await _service.getBooking(widget.bookingId);
    final payments = await _service.listPayments(widget.bookingId);
    return BookingDetails(myBooking: myBooking, payments: payments);
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cancelling = true);
    try {
      await _service.cancelBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      setState(() {
        _cancelling = false;
        _future = _load();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: FutureBuilder<BookingDetails>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // UI audit #15: the error state now has a Retry button.
          if (snap.hasError) {
            return ErrorView(
              message: 'Could not load this booking. Please try again.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final d = snap.data!;
          final b = d.booking;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DetailSection(
                title: 'Booking ${b.referenceNo}',
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BookingStatusBadge(status: b.displayStatus()),
                  ),
                ],
              ),
              DetailSection(
                title: 'Items',
                children: [
                  if (d.items.isEmpty) const Text('No items found.'),
                  for (final item in d.items)
                    Text('${item.name} (${item.size})'),
                ],
              ),
              DetailSection(
                title: 'Dates',
                children: [
                  Text('Pickup: ${formatDate(b.pickupDate)}'),
                  Text('Event: ${formatDate(b.eventDate)}'),
                  Text('Return: ${formatDate(b.returnDate)}'),
                ],
              ),
              DetailSection(
                title: 'Payments',
                children: [
                  Text('Option: ${b.paymentOption.label}'),
                  const SizedBox(height: 4),
                  if (d.payments.isEmpty)
                    const Text('No payments recorded yet.'),
                  for (final p in d.payments)
                    Text(
                      // methodLabel: "GCash", not the database value "gcash".
                      '${formatPeso(p.amount)} • ${p.kind.label} • '
                      '${p.methodLabel}'
                      ' • ${formatDateOrDash(p.createdAt)}',
                    ),
                ],
              ),
              DetailSection(
                title: 'Summary',
                children: [
                  Text('Total: ${formatPeso(b.totalAmount)}'),
                  Text('Paid: ${formatPeso(b.amountPaid)}'),
                  Text(
                    'Balance: ${formatPeso(b.balance)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // UI audit #8: payment deadline for pending requests.
                  if (payByText(b) != null)
                    Text(
                      payByText(b)!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              if (d.canCancel) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _cancelling ? null : _confirmCancel,
                  child: _cancelling
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel booking'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
