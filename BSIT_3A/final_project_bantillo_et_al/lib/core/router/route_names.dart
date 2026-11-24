// Every route name and path in one place.
//
// Features navigate ONLY by name, for example:
//   context.goNamed(RouteNames.itemDetails, pathParameters: {'itemId': id});
//   context.pushNamed(RouteNames.reserveDates, pathParameters: {'itemId': id});
// Never import another feature's screen to navigate to it.
//
// OWNER: team lead. Change only via a reviewed PR. Adding a route to your
// feature? Add its name + path here in the same PR and tag the lead.

/// Route names used with goNamed / pushNamed.
abstract final class RouteNames {
  // Auth (team lead)
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';

  // Customer shell (Member 1 + Member 2)
  static const String browse = 'browse';
  static const String itemDetails = 'itemDetails';
  // Saved items (customer redesign 2, Member 1).
  static const String favorites = 'favorites';
  static const String assistant = 'assistant';
  static const String myBookings = 'myBookings';
  static const String customerBookingDetails = 'customerBookingDetails';
  static const String profile = 'profile';

  // Reservation flow, full screen (Member 2)
  static const String reserveDates = 'reserveDates';
  // reserveMeasurements / reserveReview removed: their screens were deleted
  // in Phase 2 (reserveDates stays for the redirect route).
  static const String bookingConfirmation = 'bookingConfirmation';

  // Staff shell (Member 1 + Member 3)
  static const String shopDashboard = 'shopDashboard';
  static const String shopCalendar = 'shopCalendar';
  static const String shopBookings = 'shopBookings';
  static const String shopBookingDetails = 'shopBookingDetails';
  static const String recordPayment = 'recordPayment';
  static const String inventory = 'inventory';
  static const String itemFormNew = 'itemFormNew';
  static const String itemFormEdit = 'itemFormEdit';
  static const String shopMore = 'shopMore';
  static const String reports = 'reports';

  // Checklists, full screen (Member 3)
  static const String releaseChecklist = 'releaseChecklist';
  static const String returnChecklist = 'returnChecklist';
}

/// Route paths. Child paths (no leading slash) are relative to their parent.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  static const String browse = '/browse';
  static const String itemDetails = 'item/:itemId'; // child of browse
  static const String favorites = 'favorites'; // child of browse

  /// Full path of the Favorites screen, for context.push.
  static const String favoritesFull = '/browse/favorites';
  static const String assistant = '/assistant';
  static const String myBookings = '/my-bookings';
  static const String customerBookingDetails = ':bookingId'; // child
  static const String profile = '/profile';

  static const String reservePrefix = '/reserve';
  static const String reserveDates = '/reserve/:itemId/dates'; // redirect only
  static const String bookingConfirmationPrefix = '/booking-confirmation';
  static const String bookingConfirmation = '/booking-confirmation/:bookingId';

  static const String shopPrefix = '/shop';
  static const String shopDashboard = '/shop/dashboard';
  static const String shopCalendar = '/shop/calendar';
  static const String shopBookings = '/shop/bookings';
  static const String shopBookingDetails = ':bookingId'; // child
  static const String recordPayment = ':bookingId/payment'; // child
  static const String inventory = '/shop/inventory';
  static const String itemFormNew = 'new'; // child of inventory
  static const String itemFormEdit = ':itemId/edit'; // child of inventory
  static const String shopMore = '/shop/more';
  static const String reports = '/shop/reports';
  static const String releaseChecklist = '/shop/checklist/release/:bookingId';
  static const String returnChecklist = '/shop/checklist/return/:bookingId';

  /// Where guests and customers land.
  static const String customerHome = browse;

  /// Where staff and owners land.
  static const String staffHome = shopDashboard;

  /// Paths that need any signed-in account. Everything under [shopPrefix]
  /// additionally needs a staff or owner role.
  static const List<String> signInRequiredPrefixes = [
    reservePrefix,
    myBookings,
    bookingConfirmationPrefix,
  ];
}

/// Query parameters understood by the Login screen (customer redesign 2).
/// Any feature may send a guest to Login with one of these, so the screen
/// can say why sign-in is needed (H2, H9):
///   `/login?from=(where to return)&reason=favorites`
abstract final class LoginReasons {
  /// Query parameter name.
  static const String param = 'reason';

  /// A guest tapped a heart: "Sign in to save favorites".
  static const String favorites = 'favorites';

  /// A guest tapped Reserve Now: "Sign in to reserve this item".
  static const String reserve = 'reserve';
}
