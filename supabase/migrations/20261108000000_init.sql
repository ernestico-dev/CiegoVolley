-- CiegoVolley · esquema inicial
-- Ejecútalo en el SQL Editor de Supabase o con `supabase db push`.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Perfiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select to authenticated using (true);

create policy "profiles_insert_own"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

-- Crea el perfil automáticamente al registrarse.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Equipos
-- ---------------------------------------------------------------------------
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 80),
  category text not null default 'Senior',
  season text,
  logo_url text,
  created_at timestamptz not null default now()
);

create index if not exists teams_owner_idx on public.teams (owner_id);

alter table public.teams enable row level security;

create policy "teams_select_authenticated"
  on public.teams for select to authenticated using (true);

create policy "teams_insert_own"
  on public.teams for insert to authenticated with check (auth.uid() = owner_id);

create policy "teams_update_own"
  on public.teams for update to authenticated
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "teams_delete_own"
  on public.teams for delete to authenticated using (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- Torneos
-- ---------------------------------------------------------------------------
create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  venue text,
  starts_on date,
  ends_on date,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'finished')),
  created_at timestamptz not null default now(),
  constraint tournaments_dates
    check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create index if not exists tournaments_owner_idx on public.tournaments (owner_id);

alter table public.tournaments enable row level security;

create policy "tournaments_select_authenticated"
  on public.tournaments for select to authenticated using (true);

create policy "tournaments_insert_own"
  on public.tournaments for insert to authenticated
  with check (auth.uid() = owner_id);

create policy "tournaments_update_own"
  on public.tournaments for update to authenticated
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "tournaments_delete_own"
  on public.tournaments for delete to authenticated using (auth.uid() = owner_id);
