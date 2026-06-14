-- ============================================================
-- Patricia's Travels — Supabase one-time setup
-- Run this once: Supabase dashboard → SQL Editor → New query → paste → Run.
-- Creates the 3 tables, the "photos" storage bucket, and the security rules
-- (everyone can read; only a logged-in owner can write).
-- ============================================================

-- 1) TABLES ---------------------------------------------------

create table if not exists public.video_links (
  trip_id    text primary key,
  url        text not null,
  updated_at timestamptz default now()
);

create table if not exists public.trip_photos (
  id           uuid primary key default gen_random_uuid(),
  trip_id      text not null,
  img_url      text not null,
  storage_path text,
  created_at   timestamptz default now()
);

create table if not exists public.outfits (
  id           uuid primary key default gen_random_uuid(),
  img_url      text not null,
  storage_path text,
  name         text not null,
  loc          text,
  year         text,
  pieces       text,
  created_at   timestamptz default now()
);

create table if not exists public.page_views (
  id         uuid primary key default gen_random_uuid(),
  visited_at timestamptz default now()
);

-- 2) TABLE PRIVILEGES ----------------------------------------
-- RLS (below) decides which rows; these GRANTs give the base access.
grant usage on schema public to anon, authenticated;
grant select on public.video_links, public.trip_photos, public.outfits to anon, authenticated;
grant insert, update, delete on public.video_links, public.trip_photos, public.outfits to authenticated;
grant insert on public.page_views to anon, authenticated;
grant select on public.page_views to authenticated;

-- 3) ROW LEVEL SECURITY --------------------------------------
alter table public.video_links enable row level security;
alter table public.trip_photos enable row level security;
alter table public.outfits     enable row level security;
alter table public.page_views  enable row level security;

-- Public read for everyone (anon visitors)
create policy "public read video_links" on public.video_links for select using (true);
create policy "public read trip_photos" on public.trip_photos for select using (true);
create policy "public read outfits"     on public.outfits     for select using (true);

-- page_views: anyone can insert (tracks visits), only owner can read the count
create policy "public insert page_views" on public.page_views for insert with check (true);
create policy "auth read page_views" on public.page_views for select to authenticated using (true);

-- Write (insert/update/delete) only for logged-in users
create policy "auth write video_links" on public.video_links for all
  to authenticated using (true) with check (true);
create policy "auth write trip_photos" on public.trip_photos for all
  to authenticated using (true) with check (true);
create policy "auth write outfits" on public.outfits for all
  to authenticated using (true) with check (true);

-- 4) STORAGE BUCKET for the actual photo files ----------------
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

-- Anyone can view files
create policy "public read photos" on storage.objects for select
  using (bucket_id = 'photos');

-- Only logged-in users can upload / change / delete files
create policy "auth upload photos" on storage.objects for insert
  to authenticated with check (bucket_id = 'photos');
create policy "auth update photos" on storage.objects for update
  to authenticated using (bucket_id = 'photos');
create policy "auth delete photos" on storage.objects for delete
  to authenticated using (bucket_id = 'photos');
