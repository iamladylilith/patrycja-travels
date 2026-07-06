-- ============================================================
-- Patricia's Travels — Guest logins + visit counts (one-time setup)
-- Run once: Supabase dashboard → SQL Editor → New query → paste all → Run.
-- Safe to re-run. Nothing here exposes passwords to visitors.
-- ============================================================

-- 1) TABLE -----------------------------------------------------
create table if not exists public.guest_logins (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,     -- stored lower-case
  pass       text not null,
  visits     int  not null default 0,  -- how many times this person opened the site
  last_seen  timestamptz,
  created_at timestamptz default now()
);

-- 2) PRIVILEGES ------------------------------------------------
-- Only the logged-in owner may touch the table directly.
-- Visitors NEVER read it; they only call the two functions below.
revoke all on public.guest_logins from anon;
grant select, insert, update, delete on public.guest_logins to authenticated;

-- 3) ROW LEVEL SECURITY (owner-only, like page_views counts) ---
alter table public.guest_logins enable row level security;
drop policy if exists "owner manage guest_logins" on public.guest_logins;
create policy "owner manage guest_logins" on public.guest_logins
  for all to authenticated using (true) with check (true);

-- 4) VERIFY a login (server-side; never returns the list) -------
create or replace function public.verify_guest_login(p_name text, p_pass text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare matched boolean;
begin
  update public.guest_logins
     set visits = visits + 1, last_seen = now()
   where name = lower(trim(p_name)) and pass = p_pass
  returning true into matched;
  return coalesce(matched, false);
end;
$$;

-- 5) RECORD a repeat visit by a remembered guest ---------------
create or replace function public.record_guest_visit(p_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.guest_logins
     set visits = visits + 1, last_seen = now()
   where name = lower(trim(p_name));
end;
$$;

-- 6) Let visitors (anon) EXECUTE only these two functions ------
grant execute on function public.verify_guest_login(text, text) to anon, authenticated;
grant execute on function public.record_guest_visit(text)       to anon, authenticated;

-- 7) Seed the existing test login so nothing breaks ------------
insert into public.guest_logins (name, pass)
values ('person1', '123x')
on conflict (name) do nothing;
