-- =============================================================================
-- 0002_shop_bookings.sql : staff RPCs for the shop_bookings feature.
--
-- Adds two functions the staff app calls with supabase.rpc():
--   * record_payment(...)        insert a payment, update amount_paid and
--                                move pending -> reserved, in ONE transaction.
--   * update_booking_status(...) the only allowed staff status changes.
--
-- Run AFTER 0001_init.sql and 0006_table_grants.sql:
--   * Dashboard: SQL Editor -> paste this file -> Run, or
--   * CLI:       supabase db push
--
-- Both functions are SECURITY DEFINER (they run with the owner's rights) so
-- they can check every rule in one place. Each one therefore starts by
-- checking public.is_staff(); customers get an error.
--
-- This project has NO default grants, so each function ends with an
-- explicit `grant execute ... to authenticated`.
--
-- Error messages are written for staff to read. The app shows them as-is
-- (errcode P0001, the default for RAISE EXCEPTION). Two special cases:
--   * 42501  : caller is not staff or owner.
--   * 23P01  : the exclusion constraint on booking_items rejected the
--              reserve (another blocking booking holds the same dates).
--
-- OWNER: Member 3.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- record_payment
--
-- Rules (the Flutter form checks the same ones, see payment_rules.dart):
--   * only pending (not yet expired) or reserved bookings take payments
--   * amount > 0, at most 2 decimals, and not more than the balance
--   * 'full'    : only when nothing is paid yet, amount = total
--   * 'down'    : only when nothing is paid yet, amount = 50% of the total
--   * 'balance' : only after a full or down payment exists
--   * a full or down payment on a pending booking makes it reserved
--
-- If reserving fails because the dates were taken (23P01), the whole call is
-- rolled back, so the payment row is NOT kept either.
-- Returns the updated booking row.
-- -----------------------------------------------------------------------------
create or replace function public.record_payment(
  p_booking_id uuid,
  p_amount     numeric,
  p_kind       text,
  p_method     text
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_kind    text := lower(trim(coalesce(p_kind, '')));
  v_method  text := lower(trim(coalesce(p_method, '')));
  v_balance numeric(10, 2);
  v_half    numeric(10, 2);
begin
  -- 1. Only staff and owners may record payments.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can record payments.'
      using errcode = '42501';
  end if;

  -- 2. Load the booking and LOCK its row, so two staff recording a payment
  --    at the same moment cannot both pass the balance check.
  select * into v_booking
    from public.bookings
   where id = p_booking_id
     for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  -- 3. Status checks.
  if v_booking.status not in ('pending', 'reserved') then
    raise exception 'Payments can only be recorded for pending or reserved bookings.';
  end if;

  if v_booking.status = 'pending'
     and v_booking.expires_at is not null
     and v_booking.expires_at < now() then
    raise exception 'This request has expired. Ask the customer to submit a new booking.';
  end if;

  -- 4. Kind and method must be known values.
  if v_kind not in ('full', 'down', 'balance') then
    raise exception 'Choose a payment kind: full, down payment or balance.';
  end if;

  if v_method not in ('cash', 'gcash', 'bank') then
    raise exception 'Choose a payment method: cash, GCash or bank transfer.';
  end if;

  -- 5. Amount checks.
  if p_amount is null or p_amount <= 0 then
    raise exception 'Enter an amount greater than 0.';
  end if;

  if p_amount <> round(p_amount, 2) then
    raise exception 'Use at most 2 decimal places for the amount.';
  end if;

  v_balance := v_booking.total_amount - v_booking.amount_paid;
  v_half    := round(v_booking.total_amount * 0.5, 2);

  if p_amount > v_balance then
    raise exception 'Amount cannot be more than the balance of ₱%.',
      to_char(v_balance, 'FM999,999,990.00');
  end if;

  -- 6. Kind-specific checks.
  if v_kind in ('full', 'down') and v_booking.amount_paid > 0 then
    raise exception 'This booking already has a payment. Record the rest as a balance payment.';
  end if;

  if v_kind = 'full' and p_amount <> v_booking.total_amount then
    raise exception 'A full payment must equal the total of ₱%.',
      to_char(v_booking.total_amount, 'FM999,999,990.00');
  end if;

  if v_kind = 'down' and p_amount <> v_half then
    -- %% prints a literal percent sign inside RAISE.
    raise exception 'A down payment must be exactly 50%% of the total (₱%).',
      to_char(v_half, 'FM999,999,990.00');
  end if;

  if v_kind = 'balance' and v_booking.amount_paid = 0 then
    raise exception 'Record a full or down payment first.';
  end if;

  -- 7. Save the payment. recorded_by defaults to auth.uid() (see 0001).
  insert into public.payments (booking_id, amount, kind, method)
  values (p_booking_id, p_amount, v_kind, v_method);

  -- 8. Add it to amount_paid and reserve a pending booking.
  --    Setting status = 'reserved' fires bookings_resync_items (0001), which
  --    makes the booking_items blocking. If the dates overlap another
  --    blocking booking, Postgres raises 23P01 here and rolls back steps 7-8.
  update public.bookings
     set amount_paid = amount_paid + p_amount,
         status = case
                    when status = 'pending' and v_kind in ('full', 'down')
                      then 'reserved'
                    else status
                  end
   where id = p_booking_id
  returning * into v_booking;

  return v_booking;
end;
$$;

-- Guests must not call it; signed-in users may (the function itself rejects
-- non-staff). Postgres gives functions to PUBLIC by default, so revoke that.
revoke execute on function public.record_payment(uuid, numeric, text, text)
  from public, anon;
grant execute on function public.record_payment(uuid, numeric, text, text)
  to authenticated;


-- -----------------------------------------------------------------------------
-- update_booking_status
--
-- Allowed changes (anything else raises an error):
--   pending  -> cancelled
--   reserved -> cancelled
--   reserved -> rented_out  only if a release checklist exists AND the
--                           balance is fully paid
--   rented_out -> returned  only if a return checklist exists; the items'
--                           condition becomes cleaning_repair
--
-- pending -> reserved is NOT done here: it happens in record_payment.
-- Returns the updated booking row.
-- -----------------------------------------------------------------------------
create or replace function public.update_booking_status(
  p_booking_id uuid,
  p_new_status text
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_old     text;
  v_new     text := lower(trim(coalesce(p_new_status, '')));
begin
  -- 1. Only staff and owners may change a booking's status.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can change a booking status.'
      using errcode = '42501';
  end if;

  -- 2. Load and lock the booking.
  select * into v_booking
    from public.bookings
   where id = p_booking_id
     for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  v_old := v_booking.status;

  -- 3. Basic checks on the requested status.
  if v_new not in ('pending', 'reserved', 'rented_out',
                   'returned', 'cancelled', 'expired') then
    raise exception 'Unknown booking status "%".', p_new_status;
  end if;

  if v_new = v_old then
    raise exception 'This booking is already %.', replace(v_old, '_', ' ');
  end if;

  -- 4. Transition rules.
  if v_new = 'cancelled' and v_old in ('pending', 'reserved') then
    null;  -- always allowed

  elsif v_old = 'pending' and v_new = 'reserved' then
    raise exception 'Record a full or down payment to reserve this booking.';

  elsif v_old = 'reserved' and v_new = 'rented_out' then
    if not exists (select 1 from public.checklists
                   where booking_id = p_booking_id and kind = 'release') then
      raise exception 'Save the release checklist before marking the booking as picked up.';
    end if;
    if v_booking.amount_paid < v_booking.total_amount then
      raise exception 'Collect the remaining balance of ₱% before releasing the items.',
        to_char(v_booking.total_amount - v_booking.amount_paid, 'FM999,999,990.00');
    end if;

  elsif v_old = 'rented_out' and v_new = 'returned' then
    if not exists (select 1 from public.checklists
                   where booking_id = p_booking_id and kind = 'return') then
      raise exception 'Save the return checklist before marking the booking as returned.';
    end if;

  else
    raise exception 'A % booking cannot be changed to %.',
      replace(v_old, '_', ' '), replace(v_new, '_', ' ');
  end if;

  -- 5. Apply the change. bookings_resync_items (0001) updates is_blocking:
  --    cancelled / returned free the dates again.
  update public.bookings
     set status = v_new
   where id = p_booking_id
  returning * into v_booking;

  -- 6. Returned garments go to cleaning first (retired items stay retired).
  if v_new = 'returned' then
    update public.items
       set condition = 'cleaning_repair'
     where id in (select item_id from public.booking_items
                  where booking_id = p_booking_id)
       and condition <> 'retired';
  end if;

  return v_booking;
end;
$$;

revoke execute on function public.update_booking_status(uuid, text)
  from public, anon;
grant execute on function public.update_booking_status(uuid, text)
  to authenticated;


-- =============================================================================
-- Manual test (SQL Editor). The SQL Editor runs as the postgres role, where
-- auth.uid() is null, so is_staff() is false. Pretend to be a staff user by
-- setting the JWT claim first, inside a transaction you roll back:
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-USER-UUID>', 'role', 'authenticated')::text,
--     true);
--
--   -- Pick a pending booking:
--   select id, reference_no, status, total_amount, amount_paid
--     from public.bookings where status = 'pending' limit 1;
--
--   -- 50% down payment (use the real total / 2) -> status becomes reserved:
--   select status, amount_paid
--     from public.record_payment('<BOOKING-UUID>', 1750.00, 'down', 'gcash');
--
--   -- Should fail: "Save the release checklist before ..."
--   select * from public.update_booking_status('<BOOKING-UUID>', 'rented_out');
--
--   -- Should fail: "A reserved booking cannot be changed to returned."
--   select * from public.update_booking_status('<BOOKING-UUID>', 'returned');
--
--   -- Cancel works for pending or reserved:
--   select status from public.update_booking_status('<BOOKING-UUID>', 'cancelled');
--
--   rollback;   -- undo everything above
--
-- Check the grants (should list authenticated for both functions):
--   select routine_name, grantee from information_schema.routine_privileges
--   where routine_name in ('record_payment', 'update_booking_status');
-- =============================================================================
