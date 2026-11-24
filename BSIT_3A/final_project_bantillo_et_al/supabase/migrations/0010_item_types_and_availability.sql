-- =============================================================================
-- 0010_item_types_and_availability.sql : customer redesign, Phase 1.
--
--   1. items.type also allows 'long_gown' and 'bearer', so Browse can show
--      the Gowns / Long Gowns / Suits / Bearer categories.
--   2. item_busy_days(p_from, p_to): for every item, how many days between
--      p_from and p_to are already held by a reserved or rented-out
--      booking. Browse uses it for the "Few dates left" tag. It returns
--      only counts (no booking or customer data), so guests may call it.
--
-- Run AFTER 0001_init.sql and 0006_table_grants.sql. Safe to run again.
--
-- OWNER: team lead (item types) / Member 1 (catalog availability).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Item types. The 0001 check was created inline, so Postgres named it
--    items_type_check. Replace it with the longer list.
-- -----------------------------------------------------------------------------
alter table public.items drop constraint if exists items_type_check;

alter table public.items
  add constraint items_type_check
  check (type in ('gown', 'long_gown', 'suit', 'bearer'));

-- -----------------------------------------------------------------------------
-- 2. Busy days per item in a date range.
-- -----------------------------------------------------------------------------
create or replace function public.item_busy_days(p_from date, p_to date)
returns table (item_id uuid, busy_days int)
language sql
stable
security definer          -- reads booking_items, which guests cannot read
set search_path = public
as $$
  -- Each blocking booking_items row covers a date range; count the days
  -- of that range that fall inside p_from..p_to, per item.
  select bi.item_id,
         count(distinct d)::int as busy_days
    from public.booking_items bi
    cross join lateral generate_series(
      greatest(lower(bi.rental_period), p_from),
      least(upper(bi.rental_period) - 1, p_to),   -- upper bound is exclusive
      interval '1 day'
    ) as d
   where bi.is_blocking
     and bi.rental_period && daterange(p_from, p_to, '[]')
   group by bi.item_id;
$$;

-- Only counts are returned, so guests (anon) may use it on Browse.
grant execute on function public.item_busy_days(date, date)
  to anon, authenticated;

-- -----------------------------------------------------------------------------
-- Check (SQL Editor):
--   select * from public.item_busy_days(current_date, current_date + 30);
--   insert into public.items (name, type, age_group, size, price)
--   values ('Test Long Gown', 'long_gown', 'adult', 'M', 3000);  -- works now
-- -----------------------------------------------------------------------------
