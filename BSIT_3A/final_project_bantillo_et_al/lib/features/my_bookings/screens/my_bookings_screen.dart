// My Bookings: the signed-in customer's bookings, newest first, each with a
// status chip. Tapping a card opens CustomerBookingDetails.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/features/my_bookings/services/my_bookings_service.dart';
import 'package:orange150_rental/features/my_bookings/widgets/booking_card.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _service = MyBookingsService();
  late Future<List<MyBooking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listMyBookings();
  }

  Future<void> _reload() async {
    final next = _service.listMyBookings();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: FutureBuilder<List<MyBooking>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your bookings.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final bookings = snap.data!;
          if (bookings.isEmpty) {
            return const Center(child: Text('You have no bookings yet.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => BookingCard(
                myBooking: bookings[i],
                onTap: () async {
                  await context.pushNamed(
                    RouteNames.customerBookingDetails,
                    pathParameters: {'bookingId': bookings[i].booking.id},
                  );
                  if (mounted) _reload(); // refresh in case it was cancelled
                },
              ),
            ),
          );
        },
      ),
    );
  }
}