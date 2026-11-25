-- =============================================================================
-- 0017_staff_logins.sql : the owner creates and manages staff logins from the
-- app (More -> Staff accounts), through the manage-staff Edge Function.
-- Staff no longer register as customers first.
--
--   1. profiles.is_disabled: true while a staff login is disabled. The Edge
--      Function sets it together with the Supabase Auth ban, so the list can
--      show "Disabled". The profile and all booking history are kept.
--   2. list_staff(): now also returns is_disabled and created_at. The return
--      type changes, so 0015's version is dropped first.
--   3. Nobody but the database itself or the service role may change
--      profiles.role or profiles.is_disabled:
--        * the column UPDATE grants are restated WITHOUT them, and
--        * a trigger refuses the change when it comes from an app user
--          (anon / authenticated), whatever the grants or policies say later.
--      The Edge Function uses the service role; owner-only SECURITY DEFINER
--      functions (0015 set_user_role) run as the table owner, so both still
--      work.
--
-- No existing migration is edited. Run AFTER 0001, 0006, 0011 and 0015.
-- Safe to run more than once.
--
-- OWNER: Member 3 (shop_dashboard).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. The disabled flag (existing accounts: not disabled).
-- -----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists is_disabled boolean not null default false;

-- -----------------------------------------------------------------------------
-- 2. list_staff(): staff and owner accounts, owner first, then by name.
--    Owner only. The email comes from auth.users (not readable by the app).
-- -----------------------------------------------------------------------------
drop function if exists public.list_staff();

create function public.list_staff()
returns table (
  id          uuid,
  full_name   text,
  email       text,
  phone       text,
  role        text,
  is_disabled boolean,
  created_at  timestamptz
)
language plpgsql
stable
security definer          -- reads auth.users for the email
set search_path = public
as $$
begin
  -- Owner only.
  if not exists (
    select 1 from public.profiles p
     where p.id = auth.uid() and p.role = 'owner'
  ) then
    raise exception 'Only the owner can manage staff accounts.';
  end if;

  return query
    select p.id,
           p.full_name,
           u.email::text,
           p.phone,
           p.role,
           p.is_disabled,
           p.created_at
      from public.profiles p
      join auth.users u on u.id = p.id
     where p.role in ('staff', 'owner')
     order by (p.role = 'owner') desc,
              p.is_disabled,                      -- active staff first
              lower(coalesce(nullif(trim(p.full_name), ''), u.email));
end;
$$;

-- Guests cannot call it; signed-in users can (the owner check is inside).
revoke execute on function public.list_staff() from public, anon;
grant execute on function public.list_staff() to authenticated;

-- -----------------------------------------------------------------------------
-- 3a. Column grants: users may update only their own contact fields (as in
--     0001 + 0011). role and is_disabled are NOT in the list.
-- -----------------------------------------------------------------------------
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (full_name, phone, privacy_consent_at, address)
  on public.profiles to authenticated;

-- -----------------------------------------------------------------------------
-- 3b. Trigger guard: an app user's request can never change role or
--     is_disabled, even if a future grant or policy allowed the UPDATE.
--     current_user is 'authenticated' / 'anon' for app requests, and the
--     table owner (e.g. postgres) inside SECURITY DEFINER functions, or
--     'service_role' for the Edge Function.
-- -----------------------------------------------------------------------------
create or replace function public.profiles_protect_admin_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user in ('anon', 'authenticated')
     and (new.role is distinct from old.role
          or new.is_disabled is distinct from old.is_disabled) then
    raise exception 'You cannot change the account role or status.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_admin_columns on public.profiles;
create trigger profiles_protect_admin_columns
  before update on public.profiles
  for each row execute function public.profiles_protect_admin_columns();

-- =============================================================================
-- Manual test (SQL Editor). Everything is rolled back.
--
--   begin;
--   -- As the OWNER: the list has the new columns.
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<OWNER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select full_name, email, role, is_disabled, created_at
--     from public.list_staff();
--
--   -- As a CUSTOMER or STAFF: their own role / flag cannot be changed.
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-UUID>', 'role', 'authenticated')::text,
--     true);
--   set local role authenticated;   -- the SQL editor runs as postgres
--   update public.profiles set is_disabled = false
--    where id = '<STAFF-UUID>';                  -- permission denied
--   rollback;
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-UUID>', 'role', 'authenticated')::text,
--     true);
--   set local role authenticated;
--   update public.profiles set full_name = 'New Name'
--    where id = '<STAFF-UUID>';                  -- allowed (own name)
--   select public.list_staff();
--   -- -> "Only the owner can manage staff accounts."
--   rollback;
-- =============================================================================
