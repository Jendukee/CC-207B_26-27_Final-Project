// Navigator keys shared by the router and feature route files.
//
// rootNavigatorKey: the app's top navigator (above both tab shells). A
// route inside a shell that must also open from a full-screen page (for
// example Record payment, opened from the Bookings tab AND from the
// full-screen checklists) sets `parentNavigatorKey: rootNavigatorKey`.
// Without it, pushing that route from a full-screen page builds the staff
// shell a second time and Flutter throws
// "!keyReservation.contains(key)" (duplicate page keys).
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/widgets.dart';

/// The app's root navigator (passed to GoRouter.navigatorKey).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
