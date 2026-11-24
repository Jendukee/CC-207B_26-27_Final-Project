-- =============================================================================
-- 0011_econtract.sql : the shop's paper reservation form as an e-contract
-- (customer redesign, Phase 2).
--
--   1. New booking columns for the form and the typed signature.
--   2. profiles.address (optional, the customer may save it from checkout).
--   3. create_reservation(...) replaced by a version that stores the
--      e-contract and REJECTS a booking without a signature.
--
-- (long_gown / bearer item types were already added in 0010.)
--
-- Run AFTER 0001, 0006, 0008, 0009 and 0010. Safe to run more than once.
--
-- OWNER: Member 2 (reservation) / team lead (profiles column).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Booking columns (all optional except where the function requires them).
-- -----------------------------------------------------------------------------
alter table public.bookings
  add column if not exists facebook_account         text
    check (char_length(facebook_account) <= 200),
  add column if not exists customer_address         text
    check (char_length(customer_address) <= 200),
  add column if not exists preferred_fitting_date   date,
  add column if not exists notes                    text
    check (char_length(notes) <= 500),
  add column if not exists signed_name              text
    check (char_length(signed_name) <= 120),
  -- The exact terms and shop details shown when the customer signed.
  add column if not exists terms_snapshot           jsonb,
  add column if not exists preferred_payment_method text
    check (preferred_payment_method in ('cash', 'gcash', 'bank'));

-- -----------------------------------------------------------------------------
-- 2. profiles.address. Customers may update it on their own row (the same
--    column-level grant pattern as 0001: role is still NOT updatable).
-- -----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists address text
    check (char_length(address) <= 200);

grant update (address) on public.profiles to authenticated;

-- -----------------------------------------------------------------------------
-- 3. create_reservation with the e-contract.
--    The argument list changes, so the old 5-argument version (0009) is
--    dropped first; otherwise Postgres would keep both side by side.
-- -----------------------------------------------------------------------------
drop function if exists public.create_reservation(uuid, date, text, jsonb, text);

create or replace function public.create_reservation(
  p_item_id                  uuid,
  p_event_date               date,
  p_payment_option           text,
  p_measurements             jsonb,
  p_terms_version            text,
  p_signed_name              text,
  p_terms_acknowledged_at    timestamptz,
  p_terms_snapshot           jsonb,
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
  v_name     text;                                        -- profile name
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

  -- 2. The signature (replaces the paper signature line) ----------------------
  if coalesce(trim(p_signed_name), '') = '' or p_terms_acknowledged_at is null then
    raise exception 'Sign the rental agreement: type your full name and agree to the terms.';
  end if;

  if coalesce(trim(p_terms_version), '') = ''
     or p_terms_snapshot is null
     or jsonb_typeof(p_terms_snapshot -> 'terms') is distinct from 'array' then
    raise exception 'The rental terms are missing. Please reload and try again.';
  end if;

  -- The typed name must match the customer's profile name, ignoring case
  -- and extra spaces (the app saves Card 1's name to the profile first).
  select full_name into v_name from public.profiles where id = v_customer;
  if lower(regexp_replace(trim(coalesce(v_name, '')), '\s+', ' ', 'g'))
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
    terms_snapshot, signed_name,
    customer_address, facebook_account, preferred_fitting_date, notes,
    preferred_payment_method,
    expires_at
  )
  values (
    v_customer, 'pending', p_payment_option, v_item.price, 0,
    v_pickup, p_event_date, v_return,
    coalesce(p_measurements, '{}'::jsonb), p_terms_version,
    now(),                                   -- server time of signing
    p_terms_snapshot, trim(p_signed_name),
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
  text, text, date, text, text
) from public, anon;
grant execute on function public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, date, text, text
) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as a customer whose profile name is "Ana Cruz":
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select reference_no, signed_name, preferred_payment_method, expires_at
--     from public.create_reservation('<ITEM-UUID>', current_date + 10, 'half',
--          '{}', '2026-11', 'ana  CRUZ', now(),
--          '{"terms": ["Strictly no down payment, no reservation."]}',
--          'Jaro, Iloilo City', 'fb.com/ana', null, 'Please steam it', 'gcash');
--   -- No signature -> "Sign the rental agreement: ..."
--   select * from public.create_reservation('<ITEM-UUID>', current_date + 10,
--          'half', '{}', '2026-11', '', now(), '{"terms": []}');
--   rollback;
-- =============================================================================
