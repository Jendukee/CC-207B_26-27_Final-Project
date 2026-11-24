-- Customer requests for staff to review personal-data deletion.
-- This records a request only; it does not delete the auth account or records.
-- Run after 0001_init.sql and 0006_table_grants.sql.

create table public.data_deletion_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  reason      text check (reason is null or char_length(reason) <= 500),
  status      text not null default 'pending'
                check (status in ('pending', 'in_review', 'completed', 'rejected')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id) on delete set null,
  staff_note  text check (staff_note is null or char_length(staff_note) <= 1000)
);

create index data_deletion_requests_user_created_idx
  on public.data_deletion_requests (user_id, created_at desc);

create unique index data_deletion_requests_one_open_per_user_idx
  on public.data_deletion_requests (user_id)
  where status in ('pending', 'in_review');

alter table public.data_deletion_requests enable row level security;

create policy "data deletion requests: read own, staff read all"
  on public.data_deletion_requests for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

create policy "data deletion requests: customers insert own pending"
  on public.data_deletion_requests for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and reviewed_at is null
    and reviewed_by is null
    and staff_note is null
  );

create policy "data deletion requests: staff update"
  on public.data_deletion_requests for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

grant usage on schema public to authenticated;
revoke all on public.data_deletion_requests from anon, authenticated;
grant select on public.data_deletion_requests to authenticated;
grant insert (user_id, reason) on public.data_deletion_requests to authenticated;
grant update (status, reviewed_at, reviewed_by, staff_note)
  on public.data_deletion_requests to authenticated;
