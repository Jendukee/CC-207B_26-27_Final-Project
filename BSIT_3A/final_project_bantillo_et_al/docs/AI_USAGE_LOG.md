# AI Usage Log

Every member logs each meaningful use of an AI tool. That includes code generation, debugging help, explanations and documentation drafts. Add your row in the same PR as the work it affected. Be specific about what **you** changed: you must be able to explain your own feature code at the Individual Code Defense.

| Member | Date | AI tool | What it was used for / prompt summary | What was generated | What the member changed |
|---|---|---|---|---|---|
| Team lead | 2026-11-23 | Claude Code (Claude Opus 5.5) | Set up the starter skeleton: folder structure, env/secrets handling, go_router shells and auth guard, theme, shared widgets/models, Supabase migration/seed, edge function stub, collaboration docs. Instructed **not** to implement feature logic. | Flutter project scaffold; `lib/core/*`, `lib/shared/models/*`; working Login/Register/Splash (auth feature); placeholder screens and stub services for every other feature; `supabase/migrations/0001_init.sql`, `seed.sql`, `functions/ai-assistant/index.ts` (stub); README, CONTRIBUTING, CODEOWNERS, PR template, this log, topic coverage. | _Lead: fill in after reviewing (e.g. replaced placeholder usernames in CODEOWNERS, adjusted RLS, tested auth against the real project)._ |
