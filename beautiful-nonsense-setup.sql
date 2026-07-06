-- ============================================================
--  "Beautiful Nonsense" — one-time database setup
--  Run this once:  Supabase dashboard → SQL Editor → New query → paste → Run.
--  Mirrors exactly how your trip_photos / outfits tables are set up
--  (everyone can read; only a logged-in owner can add/delete).
--  Photos themselves live in your existing "photos" storage bucket —
--  no new bucket needed. Safe to run more than once.
-- ============================================================

-- 1) TABLE  (same column shape as public.trip_photos)
create table if not exists public.random_photos (
  id           uuid primary key default gen_random_uuid(),
  img_url      text not null,
  storage_path text,
  created_at   timestamptz default now()
);

-- 2) PRIVILEGES (base access; the security rules below decide the rest)
grant usage on schema public to anon, authenticated;
grant select on public.random_photos to anon, authenticated;
grant insert, update, delete on public.random_photos to authenticated;

-- 3) ROW LEVEL SECURITY
alter table public.random_photos enable row level security;

-- Everyone can READ the photos
drop policy if exists "public read random_photos" on public.random_photos;
create policy "public read random_photos" on public.random_photos for select using (true);

-- Only YOU (logged in via owner mode) can ADD / DELETE
drop policy if exists "auth write random_photos" on public.random_photos;
create policy "auth write random_photos" on public.random_photos for all
  to authenticated using (true) with check (true);
