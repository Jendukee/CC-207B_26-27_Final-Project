// "Request submitted" screen, shown after checkout (customer redesign,
// Phase 1): success icon, reference number, "Pay ₱Y by <deadline>",
// payment instructions for the chosen method (GCash number with Copy),
// the shop contact, and "View my booking" / "Back to browse".
//
// Reached with go (not push) from checkout, so Back does not return to
// the submitted form. Shop details come from core/config/shop_contact.dart.
//
// OWNER: Member 2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/config/shop_contact.dart';
import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/core/widgets/brand_app_bar.dart';
import 'package:orange150_rental/core/widgets/contact_shop.dart';
import 'package:orange150_rental/core/widgets/error_view.dart';
import 'package:orange150_rental/core/widgets/loading_view.dart';
import 'package:orange150_rental/core/widgets/payment_instructions.dart';
import 'package:orange150_rental/core/widgets/section_card.dart';
import 'package:orange150_rental/core/widgets/status_chip.dart';
import 'package:orange150_rental/features/reservation/services/reservation_service.dart';
import 'package:orange150_rental/shared/models/booking.dart';
import 'package:orange150_rental/shared/models/payment_plan.dart';

/// The Request submitted screen.
class BookingConfirmationScreen extends StatefulWidget {
  /// Creates the screen for [bookingId]. The payment method chosen at
  /// checkout is read from the booking (bookings.preferred_payment_method,
  /// migration 0011), not from the link.
  const BookingConfirmationScreen({super.key, required this.bookingId});

  /// Path parameter.
  final String bookingId;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final ReservationService _service = ReservationService();
  late Future<Booking> _future = _service.getBooking(widget.bookingId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      // Customer redesign 2: shared header with the Orange 150 mark (H4).
      appBar: BrandAppBar(
        title: 'Request submitted',
        automaticallyImplyLeading: false, // nothing to go back to
      ),
      body: FutureBuilder<Booking>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading your request...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message:
                  'Your request was sent, but this page could not load. '
                  'Try again, or open My Bookings.',
              onRetry: () => setState(
                () => _future = _service.getBooking(widget.bookingId),
              ),
            );
          }
          return _content(snapshot.requireData, theme);
        },
      ),
    );
  }

  Widget _content(Booking booking, ThemeData theme) {
    final payNow = PaymentPlan.dueNow(
      booking.totalAmount,
      booking.paymentOption,
    );
    final deadline = booking.expiresAt;
    const gap = EdgeInsets.fromLTRB(8, 0, 8, 8);

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        // Success header.
        const Icon(Icons.check_circle, size: 72, color: AppColors.success),
        const SizedBox(height: 8),
        Text(
          'Request submitted',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Center(child: StatusChip.booking(booking.displayStatus())),
        const SizedBox(height: 16),

        SectionCard(
          margin: gap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reference number', style: theme.textTheme.labelLarge),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      booking.referenceNo,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy reference number',
                    onPressed: () => copyWithSnack(
                      context,
                      booking.referenceNo,
                      'Reference number copied.',
                    ),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const Divider(),
              // What to pay, and by when.
              Text(
                deadline == null
                    ? 'Pay ${Formatters.peso(payNow)} to reserve your dates'
                    : 'Pay ${Formatters.peso(payNow)} by '
                          '${Formatters.dateTime(deadline)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.paymentOption.label}. Unpaid requests expire at '
                'the deadline. Strictly no down payment, no reservation.',
              ),
            ],
          ),
        ),

        // Payment instructions for the chosen method. Phase 3: the shared
        // PaymentInstructions widget, with the GCash number and the shop's
        // contact numbers pre-filled (the same card as booking details).
        SectionCard(
          title: 'How to pay',
          icon: Icons.payments_outlined,
          margin: gap,
          child: PaymentInstructions(
            method: booking.preferredPaymentMethod,
            referenceNo: booking.referenceNo,
          ),
        ),

        SectionCard(
          title: ShopContact.name,
          icon: Icons.storefront_outlined,
          margin: gap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ShopContact.address),
              const SizedBox(height: 4),
              Text('Contact: ${ShopContact.phonesText}'),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: ContactShopButton(outlined: true),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () =>
                    context.go('${RoutePaths.myBookings}/${booking.id}'),
                child: const Text('View my booking'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.browse),
                child: const Text('Back to browse'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
