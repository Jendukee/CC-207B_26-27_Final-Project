# Orange 150 Rentals

A gown and suit rental booking app for **Orange 150**, a local rental shop. CC207B Final Project.

- **One Flutter app, three roles:** customer, staff and owner, with role-based login.
- **Guests can browse** the catalog and use the AI assistant without an account. You need an account to reserve, view bookings or open your Profile.
- **Targets:** Android, iOS and Web. Customers always get a bottom navigation bar. The staff screens also work on tablet and web: a NavigationRail replaces the bottom bar at widths of 600 px or more.
- **Backend:** Supabase (Auth, Postgres with RLS, Storage, Edge Functions).
- **AI:** Gemini, called **only** through the `ai-assistant` Supabase Edge Function. The Gemini key never ships in the app.

## Technology stack

| Technology | Version | Used for |
|---|---|---|
| Flutter | 3.47.7 (stable) | UI framework |
| Dart | 3.13.5 | Language |
| supabase_flutter | 2.18.3 | Auth, database, storage, edge functions |
| go_router | 18.1.4 | Navigation, shells, auth guard |
| intl | 0.20.3 | Peso currency and date formatting |
| table_calendar | 3.3.0 | Availability and staff calendars |
| image_picker | 1.2.4 | Item and checklist photos |
| fl_chart | 1.3.1 | Reports charts |
| Supabase Edge Functions (Deno) | n/a | Server-side Gemini proxy |

## Prerequisites

- Flutter stable (`flutter --version` should show 3.47 or newer) and Chrome for web runs.
- VS Code with the Flutter and Deno extensions (recommended in `.vscode/extensions.json`).
- Access to the team's Supabase project. The lead shares the URL and anon key privately, **never in git**.
- Optional: the [Supabase CLI](https://supabase.com/docs/guides/cli), to push migrations and deploy functions.

## Setup

All commands run from this folder (`BSIT_3A/final_project_bantillo_et_al`).

1. **Install packages**
   ```bash
   flutter pub get
   ```
2. **Create your local env file.** It is gitignored, so it is never committed.
   ```bash
   cp env.example.json env.json
   ```
   Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from Supabase, under *Project Settings → API*. Keep `AI_FUNCTION_NAME` as `ai-assistant`.
   If you skip this step, the app shows a "Missing env.json" screen instead of crashing.
3. **Create the database.** The lead does this once per Supabase project.
   - Dashboard: open *SQL Editor*, paste and run `supabase/migrations/0001_init.sql`, then do the same for `supabase/seed.sql`.
   - Or with the CLI: `supabase init` (only if `supabase/config.toml` is missing), then `supabase link --project-ref <ref>`, then `supabase db push`.
   - For faster testing, you can turn off *Authentication → Providers → Email → Confirm email*.
4. **Set the Gemini secrets and deploy the edge function.** The lead or Member 1 does this.
   ```bash
   supabase secrets set GEMINI_API_KEY=your-key GEMINI_MODEL=gemini-2.5-flash
   supabase functions deploy ai-assistant
   ```
   For local function testing, copy `supabase/functions/.env.example` to `supabase/functions/.env`. That file is gitignored.
5. **Run the app**
   ```bash
   flutter run --dart-define-from-file=env.json
   flutter run -d chrome --dart-define-from-file=env.json
   ```
   Or press **F5** in VS Code. `.vscode/launch.json` already passes `--dart-define-from-file=env.json`.
6. **Make a staff account.** Register in the app, then run the `update public.profiles set role = 'staff' ...` snippet from `supabase/seed.sql`. To sign in as staff, open *Profile* and tap *Staff sign in*.

## Folder ownership

Each member works **only** in their own folders. The table is enforced by `.github/CODEOWNERS` at the repository root.

| Path | Owner | Contents |
|---|---|---|
| `lib/main.dart`, `lib/app.dart`, `lib/core/`, `lib/shared/` | Team lead | Env, theme, router + auth guard, Supabase client, shared widgets, validators, formatters, shared models |
| `lib/features/auth/` | Team lead | Splash, Login, Register, role lookup |
| `lib/features/catalog/` | Member 1 | Browse, search, filters, item details, availability calendar |
| `lib/features/inventory/` | Member 1 | Staff add/edit items, photos, item condition |
| `lib/features/assistant/` | Member 1 | AI chat via the edge function |
| `supabase/functions/ai-assistant/` | Member 1 (logic), lead (review) | Gemini call and system prompt |
| `lib/features/reservation/` | Member 2 | Dates + conflict check, measurements, review, e-contract, confirmation |
| `lib/features/my_bookings/` | Member 2 | Customer booking list, details, cancel |
| `lib/features/profile/` | Member 2 | Measurements, contact, consent, data deletion request |
| `lib/features/shop_dashboard/` | Member 3 | Staff dashboard and the More tab |
| `lib/features/shop_calendar/` | Member 3 | Staff calendar |
| `lib/features/shop_bookings/` | Member 3 | Booking list, details, record payment, status changes |
| `lib/features/checklist/` | Member 3 | Release and return checklists, damage, photos |
| `lib/features/reports/` | Member 3 | Reports and charts |
| `supabase/migrations/`, `supabase/seed.sql` | Team lead | Schema, RLS, storage. New changes go in a new migration file |

Every feature folder has the same layout:

```
features/<feature>/
  screens/            one file per screen
  widgets/            widgets used only by this feature
  models/             models used only by this feature (shared ones go in lib/shared/models/)
  services/           <feature>_service.dart, the only place that talks to Supabase
  <feature>_routes.dart   this feature's List<RouteBase>, combined in core/router/app_router.dart
  README.md
```

**Boundaries:**
- A feature never imports another feature's `screens/` or `services/`.
- Data shared between features goes through `lib/shared/models/`.
- Navigate by name only: `context.goNamed(RouteNames.itemDetails, pathParameters: {'itemId': id})`.

## Branch rules (summary)

- Never push to `main`. Work on `feature/<member>-<short-desc>`, for example `feature/m1-browse-grid`.
- Open a PR with the template filled in. Each PR needs **one teammate review** before merge.
- Changes to `lib/core/`, `lib/shared/` or `supabase/migrations/` go through a PR that tags the lead.
- Log any AI help in `docs/AI_USAGE_LOG.md`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full rules.

## Documentation

- [docs/AI_USAGE_LOG.md](docs/AI_USAGE_LOG.md): required log of AI tool usage.
- [docs/TOPIC_COVERAGE.md](docs/TOPIC_COVERAGE.md): course topic matrix and where each topic lives in the code.
