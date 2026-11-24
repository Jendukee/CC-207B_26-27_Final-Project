-- =============================================================================
-- 0013_customer_cancel_pending_only.sql : customers may cancel ONLY while a
-- booking is Pending (customer redesign, Phase 3).
--
-- Rental terms 2 and 9: the reservation fee is non-refundable and there is
-- no cancellation once it is paid. 0001's cancel_my_booking also let
-- customers cancel Reserved bookings; this version does not.
--   * Pending and not past its payment deadline (expires_at) -> cancelled.
--   * Reserved -> rejected with the non-refundable message.
--   * Anything else -> rejected.
-- Staff still cancel Pending and Reserved bookings through
-- update_booking_status (0002), unchanged.
--
-- Same name and argument list as 0001, so the app needs no change to call
-- it. Run AFTER 0001 and 0006. Safe to run more than once.
--
-- OWNER: Member 2 (my_bookings).
-- =============================================================================

create or replace function public.cancel_my_booking(p_booking_id uuid)
returns void
language plpgsql
security definer          -- customers have no direct UPDATE on bookings
set search_path = public
as $$
declare
  v_status  text;
  v_expires timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to cancel a booking.'
      using errcode = '42501';
  end if;

  -- Lock the row so a payment recorded at the same moment cannot slip in.
  select status, expires_at into v_status, v_expires
    from public.bookings
   where id = p_booking_id
     and customer_id = auth.uid()
     for update;

  if not found then
    raise exception 'This booking could not be found.';
  end if;

  -- CHANGED: Reserved is no longer cancellable by the customer.
  if v_status = 'reserved' then
    raise exception 'Reservations are non-refundable and cannot be cancelled. Contact the shop for concerns.';
  end if;

  if v_status <> 'pending'
     or (v_expires is not null and v_expires <= now()) then
    raise exception 'This booking can no longer be cancelled.';
  end if;

  update public.bookings
     set status = 'cancelled'
   where id = p_booking_id;
end;
$$;

-- Guests cannot call it; signed-in users can.
revoke execute on function public.cancel_my_booking(uuid) from public, anon;
grant execute on function public.cancel_my_booking(uuid) to authenticated;

-- =============================================================================
-- Manual test (SQL Editor), as the booking's customer:
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<CUSTOMER-UUID>', 'role', 'authenticated')::text,
--     true);
--   select public.cancel_my_booking('<PENDING-BOOKING-UUID>');   -- works
--   select public.cancel_my_booking('<RESERVED-BOOKING-UUID>');
--   -- -> "Reservations are non-refundable and cannot be cancelled. ..."
--   rollback;
-- =============================================================================
