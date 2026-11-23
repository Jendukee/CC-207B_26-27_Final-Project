-- =============================================================================
-- 0003_checklist.sql : save a release / return checklist and change the
-- booking status in ONE transaction.
--
--   save_checklist(...)  inserts into checklists, then calls
--                        update_booking_status (0002):
--                          release -> rented_out (needs the balance paid)
--                          return  -> returned   (items -> cleaning_repair)
--
-- If any step fails (e.g. the balance is not paid yet), the whole call is
-- rolled back, so no half-saved checklist is left behind.
--
-- Run AFTER 0001_init.sql, 0002_shop_bookings.sql and 0006_table_grants.sql.
--
-- Storage: 0001 already has staff-only read/insert/update/delete policies
-- for the private checklist-photos bucket, so no new policy is needed. The
-- app uploads photos first, then passes their storage paths here
-- (<booking_id>/<kind>/<timestamp>.jpg); they are stored in
-- checklists.photo_urls.
--
-- This project has NO default grants: the function ends with an explicit
-- `grant execute ... to authenticated`.
--
-- OWNER: Member 3.
-- =============================================================================

create or replace function public.save_checklist(
  p_booking_id         uuid,
  p_kind               text,
  p_inclusions_checked jsonb,
  p_condition_notes    text,
  p_photo_paths        text[],
  p_damage_notes       text,
  p_penalty_amount     numeric
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_kind    text := lower(trim(coalesce(p_kind, '')));
  v_checks  jsonb := coalesce(p_inclusions_checked, '{}'::jsonb);
  v_photos  text[] := coalesce(p_photo_paths, '{}');
  v_penalty numeric := coalesce(p_penalty_amount, 0);
  v_prefix  text;
  v_path    text;
begin
  -- 1. Only staff and owners may save checklists.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can save checklists.'
      using errcode = '42501';
  end if;

  -- 2. Kind must be release or return.
  if v_kind not in ('release', 'return') then
    raise exception 'Unknown checklist type "%".', p_kind;
  end if;

  -- 3. Load and lock the booking so two staff cannot save at once.
  select * into v_booking
    from public.bookings
   where id = p_booking_id
     for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  -- 4. The booking must be in the right status for this checklist.
  if v_kind = 'release' and v_booking.status <> 'reserved' then
    raise exception 'Only reserved bookings can be released. This booking is %.',
      replace(v_booking.status, '_', ' ');
  end if;

  if v_kind = 'return' and v_booking.status <> 'rented_out' then
    raise exception 'Only rented out bookings can be returned. This booking is %.',
      replace(v_booking.status, '_', ' ');
  end if;

  -- 5. Inclusions: a JSON object like {"Ivory Ball Gown: Gloves": true}.
  --    On release EVERY inclusion must be ticked. On return missing items
  --    (false) are allowed.
  if jsonb_typeof(v_checks) <> 'object' then
    raise exception 'The inclusions list is not valid.';
  end if;

  if v_kind = 'release' and (
       v_checks = '{}'::jsonb
       or exists (select 1 from jsonb_each(v_checks) as e
                  where e.value is distinct from 'true'::jsonb)
     ) then
    raise exception 'Tick every inclusion before releasing the items.';
  end if;

  -- 6. Notes stay a reasonable length.
  if char_length(coalesce(p_condition_notes, '')) > 1000
     or char_length(coalesce(p_damage_notes, '')) > 1000 then
    raise exception 'Notes can be at most 1000 characters.';
  end if;

  -- 7. Penalty: 0 or more, at most 2 decimals, and only on returns.
  if v_penalty < 0 then
    raise exception 'Enter a penalty of 0 or more.';
  end if;

  if v_penalty <> round(v_penalty, 2) then
    raise exception 'Use at most 2 decimal places for the penalty.';
  end if;

  if v_kind = 'release' and v_penalty <> 0 then
    raise exception 'A penalty can only be recorded on return.';
  end if;

  -- 8. Photos must be files of THIS booking and checklist kind, so a
  --    checklist cannot point at someone else's photos.
  v_prefix := p_booking_id::text || '/' || v_kind || '/';
  foreach v_path in array v_photos loop
    if left(v_path, char_length(v_prefix)) <> v_prefix then
      raise exception 'A photo does not belong to this checklist.';
    end if;
  end loop;

  -- 9. Save the checklist. recorded_by defaults to auth.uid() (see 0001).
  insert into public.checklists (
    booking_id, kind, inclusions_checked, condition_notes,
    photo_urls, damage_notes, penalty_amount
  )
  values (
    p_booking_id, v_kind, v_checks, nullif(trim(p_condition_notes), ''),
    v_photos, nullif(trim(p_damage_notes), ''), v_penalty
  );

  -- 10. Change the status with the rules from 0002. It sees the checklist
  --     we just inserted. Release also checks that the balance is paid;
  --     return also moves the items to cleaning_repair. If it raises an
  --     error, step 9 is rolled back too.
  v_booking := public.update_booking_status(
    p_booking_id,
    case v_kind when 'release' then 'rented_out' else 'returned' end
  );

  return v_booking;
end;
$$;

-- Guests must not call it; signed-in users may (the function itself rejects
-- non-staff). Postgres gives functions to PUBLIC by default, so revoke that.
revoke execute on function
  public.save_checklist(uuid, text, jsonb, text, text[], text, numeric)
  from public, anon;
grant execute on function
  public.save_checklist(uuid, text, jsonb, text, text[], text, numeric)
  to authenticated;


-- =============================================================================
-- Manual test (SQL Editor). Pretend to be a staff user inside a transaction
-- you roll back (the SQL Editor itself is not a staff user):
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-USER-UUID>', 'role', 'authenticated')::text,
--     true);
--
--   -- A reserved booking that still owes money -> fails with
--   -- "Collect the remaining balance ...", and no checklist row is kept:
--   select * from public.save_checklist('<BOOKING-UUID>', 'release',
--     '{"Ivory Ball Gown: Garment": true, "Ivory Ball Gown: Gloves": true}',
--     'Clean, no stains', '{}', null, 0);
--
--   -- Not every inclusion ticked -> "Tick every inclusion ..."
--   select * from public.save_checklist('<BOOKING-UUID>', 'release',
--     '{"Ivory Ball Gown: Gloves": false}', null, '{}', null, 0);
--
--   -- Return with a missing item and a penalty (booking must be rented_out):
--   select status from public.save_checklist('<BOOKING-UUID>', 'return',
--     '{"Ivory Ball Gown: Garment": true, "Ivory Ball Gown: Gloves": false}',
--     'Hem slightly dirty', '{}', 'Gloves not returned', 250);
--
--   select * from public.checklists where booking_id = '<BOOKING-UUID>';
--   rollback;   -- undo everything above
--
-- Check the grant:
--   select grantee from information_schema.routine_privileges
--   where routine_name = 'save_checklist';
-- =============================================================================
