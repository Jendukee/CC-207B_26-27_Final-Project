-- =============================================================================
-- 0006_table_grants.sql : let the app's database roles use the tables.
--
-- Why: newer Supabase projects no longer grant the API roles (anon =
-- guests, authenticated = signed-in users) access to tables you create.
-- Without these grants every request fails with
--   42501 "permission denied for table profiles"
-- and, for example, staff are treated as customers because their role
-- cannot be read.
--
-- These grants only open the tables to the API. WHICH ROWS each user may
-- read or change is still decided by the Row Level Security policies in
-- 0001_init.sql (e.g. customers only see their own bookings).
--
-- Run AFTER 0001_init.sql. It does not depend on 0002-0005, so it can be
-- run right away. Safe to run more than once.
--
-- OWNER: team lead.
-- =============================================================================

-- The API roles need to reach objects in the public schema at all.
grant usage on schema public to anon, authenticated;

-- profiles ---------------------------------------------------------------------
-- Read: own row (staff read all) via RLS. Rows are created by the
-- handle_new_user trigger. UPDATE stays limited to the columns 0001 grants
-- (full_name, phone, privacy_consent_at), so users cannot change `role`.
grant select on public.profiles to authenticated;

-- measurements -----------------------------------------------------------------
grant select, insert, update, delete on public.measurements to authenticated;

-- items ------------------------------------------------------------------------
-- Guests may browse the catalog; only staff may write (RLS).
grant select on public.items to anon, authenticated;
grant insert, update, delete on public.items to authenticated;

-- bookings ---------------------------------------------------------------------
-- No DELETE: bookings are cancelled, never deleted.
grant select, insert, update on public.bookings to authenticated;

-- booking_items ----------------------------------------------------------------
grant select, insert, update, delete on public.booking_items to authenticated;

-- payments ---------------------------------------------------------------------
grant select, insert, update, delete on public.payments to authenticated;

-- checklists -------------------------------------------------------------------
grant select, insert, update on public.checklists to authenticated;

-- Functions used inside RLS policies and by the app --------------------------
-- RLS policies call is_staff() as the requesting role, so it needs EXECUTE.
grant execute on function public.is_staff() to anon, authenticated;
grant execute on function public.get_blocked_dates(uuid, date, date)
  to anon, authenticated;
grant execute on function public.cancel_my_booking(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Check: should list SELECT for authenticated on profiles.
--   select grantee, privilege_type
--   from information_schema.role_table_grants
--   where table_schema = 'public' and table_name = 'profiles';
-- -----------------------------------------------------------------------------
