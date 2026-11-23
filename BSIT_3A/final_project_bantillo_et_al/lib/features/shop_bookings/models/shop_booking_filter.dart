// Search and filter settings for the staff bookings list.
//
// The same settings can come from the URL query, so other screens (e.g. the
// shop dashboard) can open a pre-filtered list by path only:
//   /shop/bookings?status=reserved&from=2026-12-01&to=2026-12-31&q=O150
//
//   status : a bookings.status value (pending, reserved, rented_out, ...)
//   from   : earliest event date, yyyy-MM-dd
//   to     : latest event date, yyyy-MM-dd
//   q      : search text (reference number or customer name)
//
// OWNER: Member 3.

import 'package:orange150_rental/core/utils/formatters.dart';
import 'package:orange150_rental/shared/models/booking_status.dart';

/// Immutable filter for the bookings list.
class ShopBookingFilter {
  /// Creates a filter. All fields are optional; an empty filter shows all.
  const ShopBookingFilter({this.status, this.query = '', this.from, this.to});

  /// Reads the filter from URL query parameters (bad values are ignored).
  factory ShopBookingFilter.fromQuery(Map<String, String> params) {
    final statusValue = params[statusKey];
    BookingStatus? status;
    for (final s in BookingStatus.values) {
      if (s.dbValue == statusValue) status = s;
    }
    return ShopBookingFilter(
      status: status,
      query: (params[queryKey] ?? '').trim(),
      from: DateTime.tryParse(params[fromKey] ?? ''),
      to: DateTime.tryParse(params[toKey] ?? ''),
    );
  }

  /// URL key for the status.
  static const String statusKey = 'status';

  /// URL key for the search text.
  static const String queryKey = 'q';

  /// URL key for the earliest event date.
  static const String fromKey = 'from';

  /// URL key for the latest event date.
  static const String toKey = 'to';

  /// Only this status, or null for all. Pending and expired use the
  /// displayed status (see BookingRules.effectiveStatus).
  final BookingStatus? status;

  /// Reference number or customer name; empty for no search.
  final String query;

  /// Earliest event date, inclusive.
  final DateTime? from;

  /// Latest event date, inclusive.
  final DateTime? to;

  /// True when a date range is set.
  bool get hasDateRange => from != null && to != null;

  /// Copy with some fields changed. Pass `clearStatus` / `clearDates` to
  /// remove those filters (null alone means "keep the old value").
  ShopBookingFilter copyWith({
    BookingStatus? status,
    bool clearStatus = false,
    String? query,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
  }) {
    return ShopBookingFilter(
      status: clearStatus ? null : (status ?? this.status),
      query: query ?? this.query,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }

  /// The filter as URL query parameters (only the fields that are set).
  Map<String, String> toQuery() => {
    if (status != null) statusKey: status!.dbValue,
    if (query.isNotEmpty) queryKey: query,
    if (from != null) fromKey: Formatters.isoDate(from!),
    if (to != null) toKey: Formatters.isoDate(to!),
  };

  // Two filters are equal when all fields match. The list screen uses this
  // to notice when the URL brings a new filter.
  @override
  bool operator ==(Object other) =>
      other is ShopBookingFilter &&
      other.status == status &&
      other.query == query &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(status, query, from, to);
}
