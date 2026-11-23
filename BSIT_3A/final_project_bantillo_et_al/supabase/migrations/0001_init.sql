-- =============================================================================
-- 0001_init.sql : Orange 150 rental app, initial schema.
--
-- Creates tables, triggers, RPCs, Row Level Security (RLS) policies and
-- storage buckets. Run once on a fresh Supabase project:
--   * Dashboard: SQL Editor -> paste this file -> Run, or
--   * CLI:       supabase db push
--
-- Key rules:
--   * Roles live in profiles.role (customer / staff / owner). New sign-ups are
--     always customers; promote staff manually (see seed.sql).
--   * items.condition is PHYSICAL state only. Availability comes from bookings.
--   * Double booking is impossible at the database level: booking_items has an
--     exclusion constraint on (item_id, rental_period) for blocking rows, and
--     a row is blocking only while its booking is reserved or rented_out.
--
-- OWNER: team lead. Changes go in a NEW migration file (0002_..., 0003_...),
-- never by editing this one after it has been applied.
-- =============================================================================

create extension if not exists btree_gist;

-- -----------------------------------------------------------------------------
-- profiles: one row per auth user.
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  full_name          text,
  phone              text,
  role               text not null default 'customer'
                       check (role in ('customer', 'staff', 'owner')),
  privacy_consent_at timestamptz,
  created_at         timestamptz not null default now()
);

-- Creates the profile when someone signs up. Reads full_name, phone and
-- privacy_consent_at from the sign-up metadata. Role is NEVER taken from
-- metadata, so users cannot make themselves staff.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, privacy_consent_at)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone',
    nullif(new.raw_user_meta_data ->> 'privacy_consent_at', '')::timestamptz
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- True when the current user is staff or owner. SECURITY DEFINER so it can
-- read profiles without recursing into the profiles RLS policies.
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('staff', 'owner')
  );
$$;

-- -----------------------------------------------------------------------------
-- measurements: one row per customer, all values in inches.
-- -----------------------------------------------------------------------------
create table public.measurements (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  chest      numeric(5, 2) check (chest    between 10 and 80),
  waist      numeric(5, 2) check (waist    between 10 and 80),
  hips       numeric(5, 2) check (hips     between 10 and 80),
  shoulder   numeric(5, 2) check (shoulder between 6  and 35),
  height     numeric(5, 2) check (height   between 24 and 96),
  inseam     numeric(5, 2) check (inseam   between 8  and 45),
  notes      text check (char_length(notes) <= 500),
  consent_at timestamptz,
  updated_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- items: the rentable gowns and suits.
-- -----------------------------------------------------------------------------
create table public.items (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 120),
  type        text not null check (type in ('gown', 'suit')),
  age_group   text not null check (age_group in ('kids', 'adult')),
  size        text not null,
  price       numeric(10, 2) not null check (price >= 0),
  description text not null default '',
  inclusions  text[] not null default '{}',
  photo_urls  text[] not null default '{}',
  -- Physical state only. Booked-or-not comes from bookings.
  condition   text not null default 'available'
                check (condition in ('available', 'cleaning_repair', 'retired')),
  created_at  timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- bookings: one rental (pickup the day before the event, return the day after).
-- -----------------------------------------------------------------------------
create table public.bookings (
  id                    uuid primary key default gen_random_uuid(),
  reference_no          text not null unique
                          default ('O150-' || to_char(now(), 'YYMMDD') || '-' ||
                                   upper(substr(md5(random()::text), 1, 6))),
  customer_id           uuid not null references public.profiles (id) on delete cascade,
  status                text not null default 'pending'
                          check (status in ('pending', 'reserved', 'rented_out',
                                            'returned', 'cancelled', 'expired')),
  payment_option        text not null check (payment_option in ('full', 'half')),
  total_amount          numeric(10, 2) not null check (total_amount >= 0),
  amount_paid           numeric(10, 2) not null default 0 check (amount_paid >= 0),
  pickup_date           date not null,
  event_date            date not null,
  return_date           date not null,
  measurements_snapshot jsonb,
  terms_version         text,
  terms_acknowledged_at timestamptz,
  expires_at            timestamptz,
  created_at            timestamptz not null default now(),
  constraint bookings_pickup_is_day_before check (pickup_date = event_date - 1),
  constraint bookings_return_is_day_after  check (return_date = event_date + 1)
);

create index bookings_customer_idx on public.bookings (customer_id);
create index bookings_status_idx   on public.bookings (status);
create index bookings_event_idx    on public.bookings (event_date);

-- -----------------------------------------------------------------------------
-- booking_items: which items a booking holds, and for which dates.
-- -----------------------------------------------------------------------------
create table public.booking_items (
  booking_id    uuid not null references public.bookings (id) on delete cascade,
  item_id       uuid not null references public.items (id) on delete restrict,
  price         numeric(10, 2) not null check (price >= 0),
  -- Inclusive pickup..return range. Set by trigger from the parent booking.
  rental_period daterange not null,
  -- True only while the parent booking is reserved or rented_out (trigger).
  is_blocking   boolean not null default false,
  primary key (booking_id, item_id),
  -- THE double-booking guard: two blocking rows for the same item can never
  -- have overlapping dates, even if two staff confirm at the same moment.
  constraint booking_items_no_overlap
    exclude using gist (item_id with =, rental_period with &&)
    where (is_blocking)
);

create index booking_items_item_idx on public.booking_items (item_id);

-- Copies the rental period and blocking flag from the parent booking, so the
-- client can never fake them.
create or replace function public.booking_items_sync_from_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
begin
  select * into b from public.bookings where id = new.booking_id;
  if not found then
    raise exception 'Booking % not found', new.booking_id;
  end if;
  new.rental_period := daterange(b.pickup_date, b.return_date, '[]');
  new.is_blocking   := b.status in ('reserved', 'rented_out');
  return new;
end;
$$;

create trigger booking_items_sync
  before insert or update on public.booking_items
  for each row execute function public.booking_items_sync_from_booking();

-- When a booking's status or dates change, re-sync its booking_items. If the
-- new status is blocking and the dates overlap another blocking booking, the
-- exclusion constraint raises an error and the whole update is rolled back.
create or replace function public.bookings_resync_items()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.booking_items
     set is_blocking = is_blocking  -- no-op write; the BEFORE trigger recomputes
   where booking_id = new.id;
  return new;
end;
$$;

create trigger bookings_resync_items
  after update of status, pickup_date, return_date on public.bookings
  for each row execute function public.bookings_resync_items();

-- -----------------------------------------------------------------------------
-- payments: recorded by staff.
-- -----------------------------------------------------------------------------
create table public.payments (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings (id) on delete cascade,
  amount      numeric(10, 2) not null check (amount > 0),
  kind        text not null check (kind in ('full', 'down', 'balance')),
  method      text not null default 'cash',
  recorded_by uuid references public.profiles (id) default auth.uid(),
  created_at  timestamptz not null default now()
);

create index payments_booking_idx on public.payments (booking_id);

-- -----------------------------------------------------------------------------
-- checklists: release (pickup) and return inspections.
-- -----------------------------------------------------------------------------
create table public.checklists (
  id                 uuid primary key default gen_random_uuid(),
  booking_id         uuid not null references public.bookings (id) on delete cascade,
  kind               text not null check (kind in ('release', 'return')),
  inclusions_checked jsonb not null default '{}'::jsonb,
  condition_notes    text,
  photo_urls         text[] not null default '{}',
  damage_notes       text,
  penalty_amount     numeric(10, 2) not null default 0 check (penalty_amount >= 0),
  recorded_by        uuid references public.profiles (id) default auth.uid(),
  created_at         timestamptz not null default now()
);

create index checklists_booking_idx on public.checklists (booking_id);

-- -----------------------------------------------------------------------------
-- RPC: get_blocked_dates. Returns ONLY dates (no booking or customer data),
-- so any visitor can see availability without seeing other people's bookings.
-- -----------------------------------------------------------------------------
create or replace function public.get_blocked_dates(
  p_item_id uuid,
  p_from    date,
  p_to      date
)
returns setof date
language sql
stable
security definer
set search_path = public
as $$
  select distinct d::date
  from public.booking_items bi
  cross join lateral generate_series(
    lower(bi.rental_period),
    upper(bi.rental_period) - 1,   -- daterange upper bound is exclusive
    interval '1 day'
  ) as d
  where bi.item_id = p_item_id
    and bi.is_blocking
    and bi.rental_period && daterange(p_from, p_to, '[]')
    and d::date between p_from and p_to
  order by 1;
$$;

grant execute on function public.get_blocked_dates(uuid, date, date) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- RPC: cancel_my_booking. Customers may cancel their own pending/reserved
-- bookings, and nothing else (they have no direct UPDATE on bookings).
-- -----------------------------------------------------------------------------
create or replace function public.cancel_my_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.bookings
     set status = 'cancelled'
   where id = p_booking_id
     and customer_id = auth.uid()
     and status in ('pending', 'reserved');
  if not found then
    raise exception 'Booking cannot be cancelled';
  end if;
end;
$$;

revoke execute on function public.cancel_my_booking(uuid) from public, anon;
grant execute on function public.cancel_my_booking(uuid) to authenticated;

-- =============================================================================
-- Row Level Security
-- =============================================================================
alter table public.profiles      enable row level security;
alter table public.measurements  enable row level security;
alter table public.items         enable row level security;
alter table public.bookings      enable row level security;
alter table public.booking_items enable row level security;
alter table public.payments      enable row level security;
alter table public.checklists    enable row level security;

-- profiles --------------------------------------------------------------------
create policy "profiles: read own, staff read all"
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff());

create policy "profiles: update own"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Users may only change these columns on their own row; `role` is not one of
-- them. Promote staff from the SQL editor (see seed.sql).
revoke update on public.profiles from anon, authenticated;
grant update (full_name, phone, privacy_consent_at) on public.profiles to authenticated;

-- measurements ----------------------------------------------------------------
create policy "measurements: read own, staff read all"
  on public.measurements for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

create policy "measurements: insert own"
  on public.measurements for insert to authenticated
  with check (user_id = auth.uid());

create policy "measurements: update own"
  on public.measurements for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "measurements: delete own"
  on public.measurements for delete to authenticated
  using (user_id = auth.uid());

-- items -----------------------------------------------------------------------
create policy "items: anyone can read"
  on public.items for select to anon, authenticated
  using (true);

create policy "items: staff insert"
  on public.items for insert to authenticated
  with check (public.is_staff());

create policy "items: staff update"
  on public.items for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "items: staff delete"
  on public.items for delete to authenticated
  using (public.is_staff());

-- bookings --------------------------------------------------------------------
create policy "bookings: read own, staff read all"
  on public.bookings for select to authenticated
  using (customer_id = auth.uid() or public.is_staff());

-- Customers create their own bookings as pending and unpaid only.
create policy "bookings: customer insert own pending"
  on public.bookings for insert to authenticated
  with check (
    public.is_staff()
    or (customer_id = auth.uid() and status = 'pending' and amount_paid = 0)
  );

-- Only staff change bookings (status, amount_paid...). Customers cancel via
-- the cancel_my_booking RPC above.
create policy "bookings: staff update"
  on public.bookings for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- booking_items ---------------------------------------------------------------
create policy "booking_items: read own, staff read all"
  on public.booking_items for select to authenticated
  using (
    public.is_staff()
    or exists (select 1 from public.bookings b
               where b.id = booking_id and b.customer_id = auth.uid())
  );

create policy "booking_items: insert into own pending booking"
  on public.booking_items for insert to authenticated
  with check (
    public.is_staff()
    or exists (select 1 from public.bookings b
               where b.id = booking_id
                 and b.customer_id = auth.uid()
                 and b.status = 'pending')
  );

create policy "booking_items: staff update"
  on public.booking_items for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "booking_items: staff delete"
  on public.booking_items for delete to authenticated
  using (public.is_staff());

-- payments --------------------------------------------------------------------
create policy "payments: read own, staff read all"
  on public.payments for select to authenticated
  using (
    public.is_staff()
    or exists (select 1 from public.bookings b
               where b.id = booking_id and b.customer_id = auth.uid())
  );

create policy "payments: staff insert"
  on public.payments for insert to authenticated
  with check (public.is_staff());

create policy "payments: staff update"
  on public.payments for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "payments: staff delete"
  on public.payments for delete to authenticated
  using (public.is_staff());

-- checklists ------------------------------------------------------------------
create policy "checklists: read own, staff read all"
  on public.checklists for select to authenticated
  using (
    public.is_staff()
    or exists (select 1 from public.bookings b
               where b.id = booking_id and b.customer_id = auth.uid())
  );

create policy "checklists: staff insert"
  on public.checklists for insert to authenticated
  with check (public.is_staff());

create policy "checklists: staff update"
  on public.checklists for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- =============================================================================
-- Storage buckets
-- =============================================================================
insert into storage.buckets (id, name, public)
values ('item-photos', 'item-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('checklist-photos', 'checklist-photos', false)
on conflict (id) do nothing;

-- item-photos: public read, staff write.
create policy "item-photos: public read"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'item-photos');

create policy "item-photos: staff insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'item-photos' and public.is_staff());

create policy "item-photos: staff update"
  on storage.objects for update to authenticated
  using (bucket_id = 'item-photos' and public.is_staff())
  with check (bucket_id = 'item-photos' and public.is_staff());

create policy "item-photos: staff delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'item-photos' and public.is_staff());

-- checklist-photos: staff only (read and write).
create policy "checklist-photos: staff read"
  on storage.objects for select to authenticated
  using (bucket_id = 'checklist-photos' and public.is_staff());

create policy "checklist-photos: staff insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'checklist-photos' and public.is_staff());

create policy "checklist-photos: staff update"
  on storage.objects for update to authenticated
  using (bucket_id = 'checklist-photos' and public.is_staff())
  with check (bucket_id = 'checklist-photos' and public.is_staff());

create policy "checklist-photos: staff delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'checklist-photos' and public.is_staff());
