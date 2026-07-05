-- ============================================================
--  "Notes to Self" — one-time database setup
--  Paste this WHOLE file into the Supabase SQL Editor and click "Run".
--  You only need to do this ONCE. It is safe to run again if unsure.
-- ============================================================

-- 1) Create the table that stores your notes
create table if not exists public.notes (
  id          uuid        primary key default gen_random_uuid(),
  text        text        not null,
  created_at  timestamptz not null default now()
);

-- 2) Turn on Row Level Security (controls who can read vs. change notes)
alter table public.notes enable row level security;

-- 3) Anyone visiting your site can READ your notes
drop policy if exists "Public can read notes" on public.notes;
create policy "Public can read notes"
  on public.notes for select
  using (true);

-- 4) Only YOU (logged in via owner mode) can ADD / EDIT / DELETE
drop policy if exists "Owner can insert notes" on public.notes;
create policy "Owner can insert notes"
  on public.notes for insert to authenticated with check (true);

drop policy if exists "Owner can update notes" on public.notes;
create policy "Owner can update notes"
  on public.notes for update to authenticated using (true);

drop policy if exists "Owner can delete notes" on public.notes;
create policy "Owner can delete notes"
  on public.notes for delete to authenticated using (true);
