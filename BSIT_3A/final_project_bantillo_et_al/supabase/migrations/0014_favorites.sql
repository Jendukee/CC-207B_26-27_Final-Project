-- =============================================================================
-- 0014_favorites.sql : customers save gowns and suits to Favorites
-- (customer redesign 2, Phase 1).
--
--   * One row per (customer, item). Saving twice is harmless (primary key);
--     the app upserts and ignores duplicates.
--   * Rows disappear on their own when the account or the item is deleted
--     (on delete cascade). Retired items are hidden by the app's query.
--   * RLS: each signed-in user can read, add and remove ONLY their own rows.
--     Guests (anon) have no access at all. There is no UPDATE: a favorite is
--     either there or not.
--
-- Run AFTER 0001 and 0006. Safe to run more than once.
--
-- OWNER: Member 1 (catalog).
-- =============================================================================

create table if not exists public.favorites (
  user_id    uuid not null references auth.users (id) on delete cascade,
  item_id    uuid not null references public.items (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

-- Newest first on the Favorites screen.
create index if not exists favorites_user_created_idx
  on public.favorites (user_id, created_at desc);

alter table public.favorites enable row level security;

drop policy if exists "favorites: read own" on public.favorites;
create policy "favorites: read own"
  on public.favorites for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "favorites: add own" on public.favorites;
create policy "favorites: add own"
  on public.favorites for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "favorites: remove own" on public.favorites;
create policy "favorites: remove own"
  on public.favorites for delete to authenticated
  using (user_id = auth.uid());

-- Grants (this project has no default grants; see 0006).
grant usage on schema public to authenticated;
revoke all on public.favorites from anon, authenticated;
grant select, insert, delete on public.favorites to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as a customer:
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   set local role authenticated;
--   insert into public.favorites (user_id, item_id)
--     values ('<CUSTOMER-UUID>', '<ITEM-UUID>');            -- works
--   select item_id from public.favorites;                   -- only own rows
--   insert into public.favorites (user_id, item_id)
--     values ('<OTHER-USER-UUID>', '<ITEM-UUID>');          -- fails (RLS)
--   delete from public.favorites where item_id = '<ITEM-UUID>';  -- works
--   rollback;
-- =============================================================================
