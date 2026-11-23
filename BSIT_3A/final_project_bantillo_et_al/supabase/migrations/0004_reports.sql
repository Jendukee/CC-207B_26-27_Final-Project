-- =============================================================================
-- 0004_reports.sql : read-only, staff-only report functions.
--
--   report_rentals_per_month(p_months)       rentals per month
--   report_top_items(p_months, p_limit)      most-rented items
--   report_revenue_per_month(p_months)       payments per month (pesos)
--
-- p_months = how many months to cover, counting back from (and including)
-- the current month. 1 to 24, default 6 (the "last 6 months").
--
-- Definitions:
--   * A RENTAL is a booking that was actually picked up: status rented_out
--     or returned. It is counted in the month of its pickup_date.
--     Pending, reserved, cancelled and expired bookings are not rentals.
--   * REVENUE is the sum of payments.amount, in the month the payment was
--     recorded (Philippine time, Asia/Manila).
--   * Every month in the range is returned, with 0 when nothing happened,
--     so the charts have no gaps.
--
-- Each function is SECURITY DEFINER + STABLE (it only reads) and starts by
-- checking public.is_staff(). This project has NO default grants, so each
-- ends with an explicit `grant execute ... to authenticated`.
--
-- Run AFTER 0001_init.sql and 0006_table_grants.sql.
--
-- OWNER: Member 3.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Helper: first day of the earliest month in the range.
-- e.g. today 2026-11-24, p_months 6 -> 2026-06-01
-- -----------------------------------------------------------------------------
create or replace function public.report_range_start(p_months int)
returns date
language sql
stable
set search_path = public
as $$
  select (date_trunc('month', (now() at time zone 'Asia/Manila'))
          - make_interval(months => greatest(1, least(coalesce(p_months, 6), 24)) - 1)
         )::date;
$$;

revoke execute on function public.report_range_start(int) from public, anon;
grant execute on function public.report_range_start(int) to authenticated;


-- -----------------------------------------------------------------------------
-- report_rentals_per_month: one row per month, oldest first.
-- -----------------------------------------------------------------------------
create or replace function public.report_rentals_per_month(p_months int default 6)
returns table (month date, rentals int)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  -- 1. Staff and owners only.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can see reports.'
      using errcode = '42501';
  end if;

  -- 2. Every month in the range, joined with the rentals that started in it.
  return query
    with months as (
      select generate_series(
               public.report_range_start(p_months),
               date_trunc('month', (now() at time zone 'Asia/Manila'))::date,
               interval '1 month'
             )::date as month
    )
    select m.month,
           count(b.id)::int as rentals
      from months m
      left join public.bookings b
        on date_trunc('month', b.pickup_date)::date = m.month
       and b.status in ('rented_out', 'returned')
     group by m.month
     order by m.month;
end;
$$;

revoke execute on function public.report_rentals_per_month(int) from public, anon;
grant execute on function public.report_rentals_per_month(int) to authenticated;


-- -----------------------------------------------------------------------------
-- report_top_items: items rented most often in the range, highest first.
-- Ties are broken by name so the order is stable.
-- -----------------------------------------------------------------------------
create or replace function public.report_top_items(
  p_months int default 6,
  p_limit  int default 5
)
returns table (item_id uuid, name text, type text, size text, rentals int)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  -- 1. Staff and owners only.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can see reports.'
      using errcode = '42501';
  end if;

  -- 2. Count each item once per rental (booking_items row) in the range.
  return query
    select i.id,
           i.name,
           i.type,
           i.size,
           count(*)::int as rentals
      from public.booking_items bi
      join public.bookings b on b.id = bi.booking_id
      join public.items i    on i.id = bi.item_id
     where b.status in ('rented_out', 'returned')
       and b.pickup_date >= public.report_range_start(p_months)
     group by i.id, i.name, i.type, i.size
     -- By position (5 = rentals, 2 = name): the output column names are
     -- also PL/pgSQL variables, so naming them here could be ambiguous.
     order by 5 desc, 2
     limit greatest(1, least(coalesce(p_limit, 5), 20));
end;
$$;

revoke execute on function public.report_top_items(int, int) from public, anon;
grant execute on function public.report_top_items(int, int) to authenticated;


-- -----------------------------------------------------------------------------
-- report_revenue_per_month: total payments per month, oldest first.
-- -----------------------------------------------------------------------------
create or replace function public.report_revenue_per_month(p_months int default 6)
returns table (month date, revenue numeric)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  -- 1. Staff and owners only.
  if not public.is_staff() then
    raise exception 'Only staff and owner accounts can see reports.'
      using errcode = '42501';
  end if;

  -- 2. Every month in the range, joined with the payments recorded in it
  --    (payments.created_at converted to Philippine time first).
  return query
    with months as (
      select generate_series(
               public.report_range_start(p_months),
               date_trunc('month', (now() at time zone 'Asia/Manila'))::date,
               interval '1 month'
             )::date as month
    )
    select m.month,
           coalesce(sum(p.amount), 0)::numeric as revenue
      from months m
      left join public.payments p
        on date_trunc('month', (p.created_at at time zone 'Asia/Manila'))::date
           = m.month
     group by m.month
     order by m.month;
end;
$$;

revoke execute on function public.report_revenue_per_month(int) from public, anon;
grant execute on function public.report_revenue_per_month(int) to authenticated;


-- =============================================================================
-- Manual test (SQL Editor). Pretend to be a staff user inside a transaction
-- (the SQL Editor itself is not a staff user):
--
--   begin;
--   select set_config('request.jwt.claims',
--     json_build_object('sub', '<STAFF-USER-UUID>', 'role', 'authenticated')::text,
--     true);
--
--   select * from public.report_rentals_per_month(6);   -- 6 rows, 0 if none
--   select * from public.report_top_items(6, 5);        -- up to 5 rows
--   select * from public.report_revenue_per_month(12);  -- 12 rows
--   rollback;
--
-- As a non-staff user each call fails with
--   "Only staff and owner accounts can see reports."
--
-- Check the grants:
--   select routine_name, grantee from information_schema.routine_privileges
--   where routine_name like 'report_%';
-- =============================================================================
