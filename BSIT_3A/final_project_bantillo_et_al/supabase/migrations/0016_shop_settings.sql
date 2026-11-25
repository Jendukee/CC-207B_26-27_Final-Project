-- =============================================================================
-- 0016_shop_settings.sql : shop settings the owner can change in the app
-- (More -> Shop settings), instead of values hardcoded in the app.
--
--   1. shop_settings: exactly ONE row (id = 1) with the shop hours, how long
--      unpaid requests stay open, the late fee per day, the address, the
--      contact numbers and the GCash number. Seeded with the values from
--      lib/core/config/shop_contact.dart and rental_terms.dart.
--   2. Everyone (guests included) may READ it: the app shows the numbers on
--      payment instructions and the Contact the shop dialog. Nobody may
--      write it directly; only through update_shop_settings().
--   3. update_shop_settings(...): owner only, checks every value, records
--      who saved it and when.
--   4. create_reservation(...): the payment deadline now uses
--      shop_settings.payment_window_hours instead of a fixed 48 hours (still
--      never later than 00:00 of the pick-up day, Manila time). Same
--      signature and grants as 0012; nothing else in it changes.
--
-- Errors are plain RAISE EXCEPTION (code P0001), so the app shows them as
-- written (core/utils/error_messages.dart).
--
-- Run AFTER 0001, 0006 and 0012. Safe to run more than once.
--
-- OWNER: Member 3 (shop_dashboard).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. The table: one row only (id is always 1).
-- -----------------------------------------------------------------------------
create table if not exists public.shop_settings (
  id                   int primary key default 1 check (id = 1),
  shop_hours           text check (char_length(shop_hours) <= 120),
  payment_window_hours int not null default 48
                         check (payment_window_hours between 1 and 168),
  late_fee_per_day     numeric(10,2) not null default 200
                         check (late_fee_per_day >= 0),
  address              text check (char_length(address) <= 200),
  contact_numbers      text[],
  gcash_number         text,
  updated_at           timestamptz,
  updated_by           uuid references auth.users (id) on delete set null
);

-- The current values (shop_contact.dart, rental_terms.dart). A second run
-- leaves an already edited row alone.
insert into public.shop_settings (
  id, shop_hours, payment_window_hours, late_fee_per_day,
  address, contact_numbers, gcash_number
)
values (
  1,
  null,                                     -- not printed on the paper form
  48,
  200,
  'Blk. 39 Lot 20 Bolilao, Mandurriao (across SM City Iloilo)',
  array['09157352844', '09544231197'],
  '09157352844'
)
on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- 2. RLS: anyone may read; no direct writes.
-- -----------------------------------------------------------------------------
alter table public.shop_settings enable row level security;

drop policy if exists "shop_settings: everyone reads" on public.shop_settings;
create policy "shop_settings: everyone reads"
  on public.shop_settings for select to anon, authenticated
  using (true);

revoke all on public.shop_settings from anon, authenticated;
grant select on public.shop_settings to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 3. update_shop_settings(...): the only way to change the row.
-- -----------------------------------------------------------------------------
create or replace function public.update_shop_settings(
  p_shop_hours           text,
  p_payment_window_hours int,
  p_late_fee_per_day     numeric,
  p_address              text,
  p_contact_numbers      text[],
  p_gcash_number         text
)
returns public.shop_settings
language plpgsql
security definer          -- app users have no UPDATE grant on the table
set search_path = public
as $$
declare
  v_hours   text := nullif(trim(coalesce(p_shop_hours, '')), '');
  v_address text := nullif(trim(coalesce(p_address, '')), '');
  v_gcash   text := trim(coalesce(p_gcash_number, ''));
  v_numbers text[];
  v_row     public.shop_settings%rowtype;
begin
  -- Owner only.
  if not exists (
    select 1 from public.profiles p
     where p.id = auth.uid() and p.role = 'owner'
  ) then
    raise exception 'Only the owner can change shop settings.';
  end if;

  -- Shop hours: optional, short.
  if v_hours is not null and char_length(v_hours) > 120 then
    raise exception 'Keep the shop hours to 120 characters or less.';
  end if;

  -- Payment window: 1 hour to 7 days.
  if p_payment_window_hours is null
     or p_payment_window_hours not between 1 and 168 then
    raise exception 'The payment window must be between 1 and 168 hours.';
  end if;

  -- Late fee: 0 or more.
  if p_late_fee_per_day is null or p_late_fee_per_day < 0 then
    raise exception 'The late fee must be 0 or more.';
  end if;
  if p_late_fee_per_day > 99999999.99 then
    raise exception 'The late fee is too large.';
  end if;

  -- Address: required, short.
  if v_address is null then
    raise exception 'Enter the shop address.';
  end if;
  if char_length(v_address) > 200 then
    raise exception 'Keep the address to 200 characters or less.';
  end if;

  -- Contact numbers: 1 to 3, each 09XXXXXXXXX, no repeats.
  select coalesce(array_agg(trim(n) order by ord), '{}')
    into v_numbers
    from unnest(coalesce(p_contact_numbers, '{}')) with ordinality as t(n, ord);

  if cardinality(v_numbers) not between 1 and 3 then
    raise exception 'Give 1 to 3 contact numbers.';
  end if;
  if exists (select 1 from unnest(v_numbers) n where n !~ '^09[0-9]{9}$') then
    raise exception 'Contact numbers must be 11 digits starting with 09.';
  end if;
  if (select count(distinct n) from unnest(v_numbers) n)
     <> cardinality(v_numbers) then
    raise exception 'Each contact number may be listed only once.';
  end if;

  -- GCash number: required, 09XXXXXXXXX.
  if v_gcash !~ '^09[0-9]{9}$' then
    raise exception 'The GCash number must be 11 digits starting with 09.';
  end if;

  insert into public.shop_settings (
    id, shop_hours, payment_window_hours, late_fee_per_day,
    address, contact_numbers, gcash_number, updated_at, updated_by
  )
  values (
    1, v_hours, p_payment_window_hours, round(p_late_fee_per_day, 2),
    v_address, v_numbers, v_gcash, now(), auth.uid()
  )
  on conflict (id) do update
    set shop_hours           = excluded.shop_hours,
        payment_window_hours = excluded.payment_window_hours,
        late_fee_per_day     = excluded.late_fee_per_day,
        address              = excluded.address,
        contact_numbers      = excluded.contact_numbers,
        gcash_number         = excluded.gcash_number,
        updated_at           = excluded.updated_at,
        updated_by           = excluded.updated_by
  returning * into v_row;

  return v_row;
end;
$$;

-- Guests cannot call it; signed-in users can (the owner check is inside).
revoke execute on function public.update_shop_settings(
  text, int, numeric, text, text[], text
) from public, anon;
grant execute on function public.update_shop_settings(
  text, int, numeric, text, text[], text
) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. create_reservation: same as 0012 except the payment deadline (marked
--    CHANGED). Same signature, so create or replace updates it in place.
-- -----------------------------------------------------------------------------
create or replace function public.create_reservation(
  p_item_id                  uuid,
  p_event_date               date,
  p_payment_option           text,
  p_measurements             jsonb,
  p_terms_version            text,
  p_signed_name              text,
  p_terms_acknowledged_at    timestamptz,
  p_terms_snapshot           jsonb,
  p_customer_full_name       text,
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
  -- CHANGED: hours to pay, from shop_settings (48 if the row is missing).
  v_window   int := coalesce(
                      (select s.payment_window_hours
                         from public.shop_settings s where s.id = 1),
                      48);
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

  -- The typed name must match the full name submitted with this booking,
  -- ignoring case and extra spaces (0012).
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
    -- CHANGED: payment deadline = the shop's payment window (was a fixed
    -- 48 hours), but never after 00:00 of pick-up day, Manila time.
    least(now() + make_interval(hours => v_window),
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

-- Same grants as 0012: guests cannot call it; signed-in users can.
revoke execute on function public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, text, date, text, text
) from public, anon;
grant execute on function public.create_reservation(
  uuid, date, text, jsonb, text, text, timestamptz, jsonb,
  text, text, text, date, text, text
) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor). Everything is rolled back.
--
--   begin;
--   -- Anyone can read the one row.
--   select * from public.shop_settings;
--
--   -- As the OWNER: saving works and records who / when.
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<OWNER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select payment_window_hours, late_fee_per_day, updated_by
--     from public.update_shop_settings(
--          'Mon to Sat, 9:00 AM to 6:00 PM', 24, 250,
--          'Blk. 39 Lot 20 Bolilao, Mandurriao (across SM City Iloilo)',
--          array['09157352844', '09544231197'], '09157352844');
--   -- Fails: "Contact numbers must be 11 digits starting with 09."
--   select public.update_shop_settings(null, 24, 250, 'Iloilo',
--          array['0915-735-2844'], '09157352844');
--   -- Fails: "The payment window must be between 1 and 168 hours."
--   select public.update_shop_settings(null, 200, 250, 'Iloilo',
--          array['09157352844'], '09157352844');
--
--   -- As a CUSTOMER: a new request now expires 24 hours from now (or at
--   -- 00:00 of pick-up day, whichever is first).
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select expires_at - now() as time_to_pay
--     from public.create_reservation('<ITEM-UUID>', current_date + 10, 'half',
--          '{}', '2026-11', 'Ana Cruz', now(),
--          '{"terms": ["Strictly no down payment, no reservation."]}',
--          'Ana Cruz');                                   -- about 24 hours
--
--   -- As STAFF: "Only the owner can change shop settings."
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-UUID>', 'role', 'authenticated')::text,
--     true);
--   select public.update_shop_settings(null, 48, 200, 'Iloilo',
--          array['09157352844'], '09157352844');
--
--   -- Direct writes are refused (no UPDATE grant). The SQL editor runs as
--   -- postgres, so switch to the app's role first.
--   set local role authenticated;
--   update public.shop_settings set late_fee_per_day = 0;   -- permission denied
--   rollback;
-- =============================================================================
