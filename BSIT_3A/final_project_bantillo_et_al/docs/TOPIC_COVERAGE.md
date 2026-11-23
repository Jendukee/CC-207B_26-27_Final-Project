# Topic Coverage Matrix

This matrix maps each required course topic to where it is demonstrated in the code. Paths are relative to `BSIT_3A/final_project_bantillo_et_al/`. Owners update their rows as features are built.

**Status legend:**
- **Skeleton**: wiring exists, but it still needs the feature owner's work.
- **Done**: implemented and demo-ready.

| Topic | Where it is demonstrated | Owner | Status |
|---|---|---|---|
| Layout widgets | `lib/core/widgets/responsive_scaffold.dart` (customer: bottom bar always; staff: NavigationBar ↔ NavigationRail at 600 px), `lib/features/catalog/screens/browse_screen.dart` (item grid), `lib/features/shop_dashboard/screens/shop_dashboard_screen.dart` (dashboard cards) | Lead, M1, M3 | Skeleton |
| Navigation and routing | `lib/core/router/app_router.dart` (two StatefulShellRoutes), `lib/core/router/auth_guard.dart` (guest/customer/staff redirects with `from`), `lib/core/router/route_names.dart`, each `lib/features/*/*_routes.dart` | Lead | Done (wiring) |
| Forms and validation | `lib/features/auth/screens/register_screen.dart` (required consent checkbox, password match), `lib/features/auth/screens/login_screen.dart`, `lib/core/utils/validators.dart`; later `lib/features/reservation/screens/reserve_measurements_screen.dart`, `lib/features/inventory/screens/item_form_screen.dart`, `lib/features/shop_bookings/screens/record_payment_screen.dart` | Lead, M1, M2, M3 | Auth done; others skeleton |
| Asynchronous operations / API calls | `lib/core/widgets/async_list_view.dart` (loading / empty / error / data), `lib/core/services/session_controller.dart`, `lib/features/*/services/*_service.dart` (e.g. `catalog_service.dart`, `shop_bookings_service.dart`) | Lead, all | Skeleton |
| Data persistence | Supabase Postgres: `supabase/migrations/0001_init.sql` (tables, RLS, exclusion constraint, RPCs), saved sessions via `supabase_flutter`, `lib/features/profile/services/profile_service.dart` (measurements), `lib/features/reservation/services/reservation_service.dart` (bookings) | Lead, M2 | Schema done; services skeleton |
| AI-powered feature | `supabase/functions/ai-assistant/index.ts` (server-side Gemini proxy, 15 s timeout), `lib/features/assistant/services/assistant_service.dart`, `lib/features/assistant/screens/assistant_screen.dart`, `lib/core/widgets/ai_label.dart` | M1 | Skeleton (stub reply) |
