# Contributing

These rules keep three people from overwriting each other's work. They also make sure each member can explain their own code at the Individual Code Defense.

## Branches

- **Never push to `main`.** `main` only changes through reviewed pull requests.
- Name branches `feature/<member>-<short-desc>`:
  - `feature/m1-browse-filters`
  - `feature/m2-reserve-dates`
  - `feature/m3-record-payment`
  - `feature/lead-auth-guard`
- For a bug fix, use `fix/<member>-<short-desc>`.
- Keep branches small and short-lived. Before opening a PR, pull `main` into your branch: `git pull origin main`.

## Where you may edit

- Edit only your own feature folders. The ownership table is in [README.md](README.md#folder-ownership).
- Change `lib/core/`, `lib/shared/`, `lib/main.dart`, `lib/app.dart` or `supabase/migrations/` **only through a PR that tags the lead**. If you need a new shared model, route name or core widget, open a small separate PR for just that change.
- Never edit `0001_init.sql` after it has been applied. Add `0002_<desc>.sql` instead.
- A feature must not import another feature's `screens/` or `services/`. Use `lib/shared/models/` for data, and `RouteNames` for navigation.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/) style. Write a short imperative summary of 72 characters or less:

```
feat(catalog): add size and price filters
fix(reservation): block dates that overlap a reserved booking
docs: update topic coverage for forms
refactor(core): extract StatusChip colors
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

## Pull requests

1. Push your branch and open a PR into `main`. Fill in the template.
2. Get **one teammate review** at minimum. CODEOWNERS requests the owner automatically.
3. Before you ask for review, check that:
   - `flutter analyze` reports no issues.
   - `flutter test` passes.
   - The app runs with `flutter run -d chrome --dart-define-from-file=env.json`.
4. Every new file has a header comment, and every significant class and method has a doc comment. The course grades this.
5. If you used AI, add a row to [docs/AI_USAGE_LOG.md](docs/AI_USAGE_LOG.md) in the same PR.

## Secrets

- Never commit `env.json`, `supabase/functions/.env`, keystores or `key.properties`. `.gitignore` already blocks them.
- The Gemini key is a Supabase secret only. Never put it in Dart code.
- If a key is ever committed by accident, tell the lead right away, so the key can be rotated in Supabase or Google AI Studio.
