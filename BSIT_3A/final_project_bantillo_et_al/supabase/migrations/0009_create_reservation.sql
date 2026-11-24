-- =============================================================================
-- 0009_create_reservation.sql : create a customer's reservation in ONE
-- safe step (UI audit, finding #8).
--
-- Before, the app did three separate things: read the price, insert the
-- booking, insert the booking item. If the last step failed, a booking
-- without an item was left behind; the app also sent the price itself, and
-- no payment deadline (expires_at) was ever set.
--
-- create_reservation(...) does it all in one transaction (all or nothing):
--   1. checks the customer is signed in and the inputs are valid
--   2. reads the item; it must exist and be available
--   3. checks no reserved / rented-out booking holds those dates
--   4. inserts the booking: status pending, price FROM THE ITEMS TABLE,
--      pickup = event - 1 day, return = event + 1 day, and the payment
--      deadline (see below)
--   5. inserts the booking item
--   6. returns the new booking
--
-- Payment deadline (expires_at):
--   48 hours after submitting, but never later than the START of the
--   pick-up day in Philippine time:
--     least(now() + 48 hours, midnight of pickup_date in Asia/Manila)
--   (A plain pickup_date::timestamptz would use the database time zone,
--   which is UTC on Supabase = 8:00 AM in Manila, not the start of the day.)
--   Because the deadline must be before pick-up day, the event must be at
--   least 2 days away (pick-up tomorrow or later).
--
-- Run AFTER 0001_init.sql and 0006_table_grants.sql.
--
-- OWNER: Member 2 (reservation feature).
-- =============================================================================

create or replace function public.create_reservation(
  p_item_id        uuid,
  p_event_date     date,
  p_payment_option text,
  p_measurements   jsonb,
  p_terms_version  text
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
  v_item     public.items%rowtype;
  v_booking  public.bookings%rowtype;
begin
  -- 1. Inputs -----------------------------------------------------------------
  if v_customer is null then
    raise exception 'Please sign in to make a reservation.'
      using errcode = '42501';
  end if;

  if p_event_date is null or v_pickup <= v_today then
    raise exception 'Choose an event date at least 2 days from today.';
  end if;

  if p_payment_option not in ('full', 'half') then
    raise exception 'Choose full payment or a 50%% down payment.';
  end if;

  if coalesce(trim(p_terms_version), '') = '' then
    raise exception 'Please agree to the rental agreement first.';
  end if;

  -- 2. The item must exist and be available -----------------------------------
  select * into v_item from public.items where id = p_item_id;

  if not found then
    raise exception 'This item no longer exists.';
  end if;

  if v_item.condition <> 'available' then
    raise exception 'This item is not available to rent right now.';
  end if;

  -- 3. No reserved / rented-out booking may hold these dates ------------------
  --    (pending requests do not block; staff confirm one of them later).
  if exists (
    select 1
      from public.booking_items bi
     where bi.item_id = p_item_id
       and bi.is_blocking
       and bi.rental_period && daterange(v_pickup, v_return, '[]')
  ) then
    raise exception 'These dates were just booked. Please choose another date.';
  end if;

  -- 4. The booking ------------------------------------------------------------
  insert into public.bookings (
    customer_id, status, payment_option, total_amount, amount_paid,
    pickup_date, event_date, return_date,
    measurements_snapshot, terms_version, terms_acknowledged_at,
    expires_at
  )
  values (
    v_customer, 'pending', p_payment_option, v_item.price, 0,
    v_pickup, p_event_date, v_return,
    coalesce(p_measurements, '{}'::jsonb), p_terms_version, now(),
    least(
      now() + interval '48 hours',
      v_pickup::timestamp at time zone 'Asia/Manila'  -- 00:00 on pick-up day
    )
  )
  returning * into v_booking;

  -- 5. The booked item (a trigger copies the rental dates from the booking) --
  insert into public.booking_items (booking_id, item_id, price)
  values (v_booking.id, p_item_id, v_item.price);

  -- 6. Done: any error above undoes BOTH inserts.
  return v_booking;
end;
$$;

-- Guests cannot call it; signed-in users can. (Postgres lets PUBLIC run
-- new functions by default, so that is revoked first.)
revoke execute on function
  public.create_reservation(uuid, date, text, jsonb, text) from public, anon;
grant execute on function
  public.create_reservation(uuid, date, text, jsonb, text) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as a customer, inside a transaction:
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select reference_no, status, total_amount, pickup_date, expires_at
--     from public.create_reservation('<ITEM-UUID>', current_date + 10,
--          'half', '{"waist": 28}', 'orange150-rental-1.0');
--   -- Too soon -> "Choose an event date at least 2 days from today."
--   select * from public.create_reservation('<ITEM-UUID>', current_date + 1,
--          'full', '{}', 'orange150-rental-1.0');
--   rollback;
-- =============================================================================
