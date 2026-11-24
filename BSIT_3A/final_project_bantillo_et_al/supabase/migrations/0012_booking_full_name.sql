-- =============================================================================
-- 0012_booking_full_name.sql : the signature is checked against the full name
-- SUBMITTED WITH THE BOOKING, not the profile name (fix before Phase 3).
--
-- Why: Card 1 of the checkout lets the customer edit their full name. 0011
-- compared signed_name to profiles.full_name, so a booking failed whenever
-- the profile name was different (or not saved yet). Now:
--   1. bookings.customer_full_name stores the name given at checkout.
--   2. create_reservation(...) takes p_customer_full_name, stores it, and
--      requires signed_name to match it (same rule: ignore case and extra
--      spaces).
--
-- Run AFTER 0011. Safe to run more than once.
--
-- OWNER: Member 2 (reservation).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. The name on the booking (older bookings keep null).
-- -----------------------------------------------------------------------------
alter table public.bookings
  add column if not exists customer_full_name text
    check (char_length(customer_full_name) <= 120);

-- -----------------------------------------------------------------------------
-- 2. create_reservation with p_customer_full_name.
--    The argument list changes, so the 13-argument version (0011) is dropped
--    first; otherwise Postgres would keep both side by side.
-- -----------------------------------------------------------------------------
drop function if exists public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, date, text, text
);

create or replace function public.create_reservation(
  p_item_id                  uuid,
  p_event_date               date,
  p_payment_option           text,
  p_measurements             jsonb,
  p_terms_version            text,
  p_signed_name              text,
  p_terms_acknowledged_at    timestamptz,
  p_terms_snapshot           jsonb,
  p_customer_full_name       text,                -- NEW: Card 1's full name
  p_customer_address         text default null,
  p_facebook_account         text default null,
  p_preferred_fitting_date   date default null,
  p_notes                    text default null,
  p_preferred_payment_method text default null
)
returns public.bookings
language plpgsql
security definer          -- runs as the owner, so it can check and insert
set search_path = public  -- always use OUR tables, never a look-alike
as $$
declare
  v_customer uuid := auth.uid();                          -- who is booking
  v_today    date := (now() at time zone 'Asia/Manila')::date;
  v_pickup   date := p_event_date - 1;                    -- day before
  v_return   date := p_event_date + 1;                    -- day after
  -- The submitted name, trimmed with inner spaces collapsed.
  v_name     text := regexp_replace(trim(coalesce(p_customer_full_name, '')),
                                    '\s+', ' ', 'g');
  v_item     public.items%rowtype;
  v_booking  public.bookings%rowtype;
begin
  -- 1. Who and what -----------------------------------------------------------
  if v_customer is null then
    raise exception 'Please sign in to make a reservation.'
      using errcode = '42501';
  end if;

  if p_event_date is null or v_pickup <= v_today then
    raise exception 'Choose an event date at least 2 days from today.';
  end if;

  if p_payment_option not in ('full', 'half') then
    raise exception 'Choose full payment or a 50%% reservation fee.';
  end if;

  if p_preferred_payment_method is not null
     and p_preferred_payment_method not in ('cash', 'gcash', 'bank') then
    raise exception 'Choose Cash, GCash or Bank transfer.';
  end if;

  if p_preferred_fitting_date is not null
     and (p_preferred_fitting_date < v_today
          or p_preferred_fitting_date >= v_pickup) then
    raise exception 'Choose a fitting date before the pick-up day.';
  end if;

  -- NEW: the booking must carry the customer's full name.
  if v_name = '' then
    raise exception 'Enter your full name.';
  end if;

  -- 2. The signature (replaces the paper signature line) ----------------------
  if coalesce(trim(p_signed_name), '') = '' or p_terms_acknowledged_at is null then
    raise exception 'Sign the rental agreement: type your full name and agree to the terms.';
  end if;

  if coalesce(trim(p_terms_version), '') = ''
     or p_terms_snapshot is null
     or jsonb_typeof(p_terms_snapshot -> 'terms') is distinct from 'array' then
    raise exception 'The rental terms are missing. Please reload and try again.';
  end if;

  -- CHANGED: the typed name must match the full name SUBMITTED WITH THIS
  -- BOOKING (Card 1), ignoring case and extra spaces. 0011 compared it to
  -- profiles.full_name instead.
  if lower(v_name)
     <> lower(regexp_replace(trim(p_signed_name), '\s+', ' ', 'g')) then
    raise exception 'Type your full name exactly as entered above.';
  end if;

  -- 3. The item must exist and be available -----------------------------------
  select * into v_item from public.items where id = p_item_id;

  if not found then
    raise exception 'This item no longer exists.';
  end if;

  if v_item.condition <> 'available' then
    raise exception 'This item is not available to rent right now.';
  end if;

  -- 4. No reserved / rented-out booking may hold these dates ------------------
  if exists (
    select 1
      from public.booking_items bi
     where bi.item_id = p_item_id
       and bi.is_blocking
       and bi.rental_period && daterange(v_pickup, v_return, '[]')
  ) then
    raise exception 'These dates were just booked. Please choose another date.';
  end if;

  -- 5. The booking, with the e-contract ---------------------------------------
  insert into public.bookings (
    customer_id, status, payment_option, total_amount, amount_paid,
    pickup_date, event_date, return_date,
    measurements_snapshot, terms_version, terms_acknowledged_at,
    terms_snapshot, signed_name, customer_full_name,
    customer_address, facebook_account, preferred_fitting_date, notes,
    preferred_payment_method,
    expires_at
  )
  values (
    v_customer, 'pending', p_payment_option, v_item.price, 0,
    v_pickup, p_event_date, v_return,
    coalesce(p_measurements, '{}'::jsonb), p_terms_version,
    now(),                                   -- server time of signing
    p_terms_snapshot, trim(p_signed_name), v_name,
    nullif(trim(p_customer_address), ''),
    nullif(trim(p_facebook_account), ''),
    p_preferred_fitting_date,
    nullif(trim(p_notes), ''),
    p_preferred_payment_method,
    -- Payment deadline: 48 hours, but never after 00:00 of pick-up day.
    least(now() + interval '48 hours',
          v_pickup::timestamp at time zone 'Asia/Manila')
  )
  returning * into v_booking;

  -- 6. The booked item (a trigger copies the rental dates from the booking) --
  insert into public.booking_items (booking_id, item_id, price)
  values (v_booking.id, p_item_id, v_item.price);

  -- 7. Done: any error above undoes BOTH inserts.
  return v_booking;
end;
$$;

-- Guests cannot call it; signed-in users can.
revoke execute on function public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, text, date, text, text
) from public, anon;
grant execute on function public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, text, date, text, text
) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as any customer (the profile name no longer
-- matters):
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   -- Passes: same name, different case and spaces.
--   select reference_no, customer_full_name, signed_name
--     from public.create_reservation('<ITEM-UUID>', current_date + 10, 'half',
--          '{}', '2026-11', 'ana  CRUZ', now(),
--          '{"terms": ["Strictly no down payment, no reservation."]}',
--          'Ana Cruz');
--   -- Fails: "Type your full name exactly as entered above."
--   select * from public.create_reservation('<ITEM-UUID>', current_date + 11,
--          'half', '{}', '2026-11', 'Maria Santos', now(), '{"terms": []}',
--          'Ana Cruz');
--   rollback;
-- =============================================================================
