-- =============================================================================
-- 0015_staff_accounts.sql : the owner manages staff accounts from the app
-- (More -> Staff accounts), instead of the SQL editor (see seed.sql).
--
--   * list_staff()                 every staff and owner account, with the
--                                  login email from auth.users
--   * set_user_role(email, role)   give a REGISTERED account staff access
--                                  ('staff') or take it away ('customer')
--
-- Rules, all checked here in the database (the app's checks are only for
-- quick feedback):
--   * Only the owner may call them. Staff and customers get
--     "Only the owner can manage staff accounts."
--   * The owner account can never be changed, and nobody can change their
--     own role, so the shop cannot lose its owner by mistake.
--   * There is no way to create an owner here: p_role is 'staff' or
--     'customer' only.
--   * Unknown email -> "No account with that email. Ask them to register
--     first." (accounts are never created here).
--
-- Why SECURITY DEFINER: `role` has no UPDATE grant for app users (0001), and
-- emails live in auth.users, which the API roles cannot read. Both functions
-- run as their owner but check the caller themselves first.
-- Errors are plain RAISE EXCEPTION (code P0001), so the app shows the
-- message as written (core/utils/error_messages.dart).
--
-- No tables, RLS policies or earlier functions are changed.
-- Run AFTER 0001 and 0006. Safe to run more than once.
--
-- OWNER: Member 3 (shop_dashboard).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- list_staff(): staff and owner accounts, owner first, then by name.
-- -----------------------------------------------------------------------------
create or replace function public.list_staff()
returns table (
  id        uuid,
  full_name text,
  email     text,
  phone     text,
  role      text
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
           p.role
      from public.profiles p
      join auth.users u on u.id = p.id
     where p.role in ('staff', 'owner')
     order by (p.role = 'owner') desc,
              lower(coalesce(nullif(trim(p.full_name), ''), u.email));
end;
$$;

-- -----------------------------------------------------------------------------
-- set_user_role(p_email, p_role): 'staff' promotes, 'customer' demotes.
-- -----------------------------------------------------------------------------
create or replace function public.set_user_role(p_email text, p_role text)
returns void
language plpgsql
security definer          -- app users cannot update profiles.role
set search_path = public
as $$
declare
  v_target uuid;
  v_current text;
begin
  -- Owner only.
  if not exists (
    select 1 from public.profiles p
     where p.id = auth.uid() and p.role = 'owner'
  ) then
    raise exception 'Only the owner can manage staff accounts.';
  end if;

  -- Only these two; an owner can never be made here.
  if p_role is null or p_role not in ('staff', 'customer') then
    raise exception 'Choose staff or customer.';
  end if;

  -- Emails are compared without case or outer spaces.
  select u.id into v_target
    from auth.users u
   where lower(u.email) = lower(trim(coalesce(p_email, '')))
   limit 1;

  if v_target is null then
    raise exception 'No account with that email. Ask them to register first.';
  end if;

  if v_target = auth.uid() then
    raise exception 'You cannot change your own role.';
  end if;

  -- Lock the row so two owners' devices cannot race.
  select p.role into v_current
    from public.profiles p
   where p.id = v_target
     for update;

  if v_current is null then
    -- auth user without a profile row (should not happen: 0001 trigger).
    raise exception 'No account with that email. Ask them to register first.';
  end if;

  if v_current = 'owner' then
    raise exception 'The owner account cannot be changed.';
  end if;

  if v_current = p_role then
    raise exception '%', case p_role
      when 'staff' then 'That account already has staff access.'
      else 'That account does not have staff access.'
    end;
  end if;

  update public.profiles
     set role = p_role
   where id = v_target;
end;
$$;

-- Guests cannot call them; signed-in users can (the owner check is inside).
revoke execute on function public.list_staff() from public, anon;
grant execute on function public.list_staff() to authenticated;

revoke execute on function public.set_user_role(text, text) from public, anon;
grant execute on function public.set_user_role(text, text) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as the owner:
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<OWNER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select * from public.list_staff();                         -- owner first
--   select public.set_user_role('new.staff@example.com', 'staff');    -- works
--   select public.set_user_role('nobody@example.com', 'staff');
--   -- -> "No account with that email. Ask them to register first."
--   select public.set_user_role('<OWNER EMAIL>', 'customer');
--   -- -> "You cannot change your own role."
--   rollback;
--
-- As a staff account the same calls raise
-- "Only the owner can manage staff accounts."
-- =============================================================================
