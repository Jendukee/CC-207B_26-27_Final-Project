// Routes owned by the AI assistant feature (Assistant tab, customer shell).
// Combined into the customer StatefulShellRoute by core/router/app_router.dart.
//
// OWNER: Member 1.

import 'package:go_router/go_router.dart';

import 'package:orange150_rental/core/router/route_names.dart';
import 'package:orange150_rental/features/assistant/screens/assistant_screen.dart';

/// Assistant chat (/assistant). Open to guests.
final List<RouteBase> assistantRoutes = [
  GoRoute(
    path: RoutePaths.assistant,
    name: RouteNames.assistant,
    builder: (context, state) => const AssistantScreen(),
  ),
];
