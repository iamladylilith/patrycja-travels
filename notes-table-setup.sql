-- ============================================================
--  "Notes to Self" — one-time database setup
--  Run this once:  Supabase dashboard → SQL Editor → New query → paste → Run.
--  Mirrors exactly how your outfits/photos tables are set up
--  (everyone can read; only a logged-in owner can add/edit/delete).
--  Safe to run more than once.
-- ============================================================

-- 1) TABLE
create table if not exists public.notes (
  id         uuid primary key default gen_random_uuid(),
  text       text not null,
  created_at timestamptz default now()
);

-- 2) PRIVILEGES (base access; the security rules below decide the rest)
grant usage on schema public to anon, authenticated;
grant select on public.notes to anon, authenticated;
grant insert, update, delete on public.notes to authenticated;

-- 3) ROW LEVEL SECURITY
alter table public.notes enable row level security;

-- Everyone can READ your notes
drop policy if exists "public read notes" on public.notes;
create policy "public read notes" on public.notes for select using (true);

-- Only YOU (logged in via owner mode) can ADD / EDIT / DELETE
drop policy if exists "auth write notes" on public.notes;
create policy "auth write notes" on public.notes for all
  to authenticated using (true) with check (true);
