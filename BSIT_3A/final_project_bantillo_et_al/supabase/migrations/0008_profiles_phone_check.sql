-- =============================================================================
-- 0008_profiles_phone_check.sql : only 09XXXXXXXXX mobile numbers in
-- profiles.phone (UI audit, finding #4).
--
-- The app already allows only 11 digits starting with 09 (Validators.phone
-- and Validators.phoneFormatters). This migration makes the database
-- enforce the same rule, so no client can store anything else.
--
--   1. Clean up existing values: fixable ones become 09XXXXXXXXX
--      ("0917 123 4567", "+63 917 123 4567", "9171234567"); anything else
--      becomes NULL.
--   2. Add the check constraint.
--   3. Make the sign-up trigger keep only valid numbers, so a bad phone in
--      the sign-up data can never make the whole sign-up fail.
--
-- Run AFTER 0001_init.sql. Safe to run more than once.
--
-- OWNER: team lead.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helper: the 09XXXXXXXXX form of a phone value, or NULL if it cannot be
-- fixed. Same rules as Validators.normalizePhone in the app.
-- -----------------------------------------------------------------------------
create or replace function public.normalize_ph_mobile(p_phone text)
returns text
language sql
immutable
set search_path = public
as $$
  select case
    -- Keep digits only, then look at the shape.
    when d ~ '^09[0-9]{9}$'  then d                     -- 09171234567
    when d ~ '^639[0-9]{9}$' then '0' || substr(d, 3)   -- 639171234567
    when d ~ '^9[0-9]{9}$'   then '0' || d              -- 9171234567
    else null
  end
  from (select regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g') as d) as x;
$$;

-- No default grants in this project: allow signed-in users only.
revoke execute on function public.normalize_ph_mobile(text) from public, anon;
grant execute on function public.normalize_ph_mobile(text) to authenticated;

-- -----------------------------------------------------------------------------
-- 1. Clean up existing rows.
-- -----------------------------------------------------------------------------
update public.profiles
   set phone = public.normalize_ph_mobile(phone)
 where phone is not null
   and phone is distinct from public.normalize_ph_mobile(phone);

-- -----------------------------------------------------------------------------
-- 2. The rule itself. Dropped first so the file can be run again.
-- -----------------------------------------------------------------------------
alter table public.profiles
  drop constraint if exists profiles_phone_ph_mobile;

alter table public.profiles
  add constraint profiles_phone_ph_mobile
  check (phone is null or phone ~ '^09[0-9]{9}$');

-- -----------------------------------------------------------------------------
-- 3. Sign-up trigger (replaces the 0001 version): identical, except the
--    phone is normalized first. Role is still NEVER taken from metadata.
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, privacy_consent_at)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    public.normalize_ph_mobile(new.raw_user_meta_data ->> 'phone'),
    nullif(new.raw_user_meta_data ->> 'privacy_consent_at', '')::timestamptz
  );
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Check (SQL Editor):
--   select phone from public.profiles where phone is not null;   -- all 09...
--   update public.profiles set phone = '0917 123 4567'
--   where id = '<SOME-UUID>';   -- fails: violates profiles_phone_ph_mobile
-- -----------------------------------------------------------------------------
