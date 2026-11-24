// A booking with its items and payments, as shown on the details screen.
//
// OWNER: Member 2.

import 'package:orange150_rental/features/my_bookings/models/my_booking.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';
import 'package:orange150_rental/shared/models/item.dart';
import 'package:orange150_rental/shared/models/payment.dart';

class BookingDetails {
  const BookingDetails({required this.myBooking, required this.payments});

  final MyBooking myBooking;
  final List<Payment> payments;

  Booking get booking => myBooking.booking;
  List<Item> get items => myBooking.items;

  /// Only pending or reserved bookings can be cancelled.
  bool get canCancel =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.reserved;
}