-- CiegoVolley · integrantes de equipo e inscripción a torneos
-- Ejecútalo después de 20261108000000_init.sql.

-- ---------------------------------------------------------------------------
-- Perfiles: email para poder buscar usuarios registrados
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists email text;

update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id
  and p.email is null;

create unique index if not exists profiles_email_key
  on public.profiles (lower(email));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data ->> 'full_name', new.email)
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name);
  return new;
end;
$$;

-- Rellena perfiles que se hayan quedado sin email o sin fila.
insert into public.profiles (id, full_name, email)
select u.id, u.raw_user_meta_data ->> 'full_name', u.email
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id
  and p.email is null;

-- ---------------------------------------------------------------------------
-- Integrantes del equipo
-- ---------------------------------------------------------------------------
create table if not exists public.team_members (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'player'
    check (role in ('player', 'coach', 'staff')),
  joined_at timestamptz not null default now(),
  primary key (team_id, user_id)
);

create index if not exists team_members_user_idx
  on public.team_members (user_id);

alter table public.team_members enable row level security;

drop policy if exists "team_members_select_authenticated" on public.team_members;
create policy "team_members_select_authenticated"
  on public.team_members for select to authenticated
  using (true);

drop policy if exists "team_members_insert_team_owner" on public.team_members;
create policy "team_members_insert_team_owner"
  on public.team_members for insert to authenticated
  with check (
    exists (
      select 1 from public.teams t
      where t.id = team_members.team_id
        and t.owner_id = auth.uid()
    )
  );

drop policy if exists "team_members_update_team_owner" on public.team_members;
create policy "team_members_update_team_owner"
  on public.team_members for update to authenticated
  using (
    exists (
      select 1 from public.teams t
      where t.id = team_members.team_id
        and t.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.teams t
      where t.id = team_members.team_id
        and t.owner_id = auth.uid()
    )
  );

drop policy if exists "team_members_delete_team_owner" on public.team_members;
create policy "team_members_delete_team_owner"
  on public.team_members for delete to authenticated
  using (
    exists (
      select 1 from public.teams t
      where t.id = team_members.team_id
        and t.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Inscripción de equipos en torneos
-- ---------------------------------------------------------------------------
create table if not exists public.tournament_teams (
  tournament_id uuid not null references public.tournaments (id) on delete cascade,
  team_id uuid not null references public.teams (id) on delete cascade,
  status text not null default 'registered'
    check (status in ('registered', 'confirmed', 'withdrawn')),
  registered_at timestamptz not null default now(),
  primary key (tournament_id, team_id)
);

create index if not exists tournament_teams_team_idx
  on public.tournament_teams (team_id);

alter table public.tournament_teams enable row level security;

drop policy if exists "tournament_teams_select_authenticated" on public.tournament_teams;
create policy "tournament_teams_select_authenticated"
  on public.tournament_teams for select to authenticated
  using (true);

drop policy if exists "tournament_teams_insert_team_owner" on public.tournament_teams;
create policy "tournament_teams_insert_team_owner"
  on public.tournament_teams for insert to authenticated
  with check (
    exists (
      select 1 from public.teams t
      where t.id = tournament_teams.team_id
        and t.owner_id = auth.uid()
    )
  );

drop policy if exists "tournament_teams_update_team_owner" on public.tournament_teams;
create policy "tournament_teams_update_team_owner"
  on public.tournament_teams for update to authenticated
  using (
    exists (
      select 1 from public.teams t
      where t.id = tournament_teams.team_id
        and t.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.teams t
      where t.id = tournament_teams.team_id
        and t.owner_id = auth.uid()
    )
  );

drop policy if exists "tournament_teams_delete_team_owner" on public.tournament_teams;
create policy "tournament_teams_delete_team_owner"
  on public.tournament_teams for delete to authenticated
  using (
    exists (
      select 1 from public.teams t
      where t.id = tournament_teams.team_id
        and t.owner_id = auth.uid()
    )
  );
