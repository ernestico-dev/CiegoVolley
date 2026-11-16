-- CiegoVolley · fases finales: cuartos, semifinales y final
-- Ejecútalo después de 20261116000003_team_owner_member.sql.

-- ---------------------------------------------------------------------------
-- Fase actual del torneo y fase de cada partido
-- ---------------------------------------------------------------------------
alter table public.tournaments
  add column if not exists stage text not null default 'league';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tournaments_stage_check'
      and conrelid = 'public.tournaments'::regclass
  ) then
    alter table public.tournaments
      add constraint tournaments_stage_check
      check (stage in ('league', 'quarterfinal', 'semifinal', 'final'));
  end if;
end;
$$;

alter table public.matches
  add column if not exists stage text not null default 'league';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'matches_stage_check'
      and conrelid = 'public.matches'::regclass
  ) then
    alter table public.matches
      add constraint matches_stage_check
      check (stage in ('league', 'quarterfinal', 'semifinal', 'final'));
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Cruces del cuadro eliminatorio
-- ---------------------------------------------------------------------------
create table if not exists public.tournament_slots (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments (id) on delete cascade,
  stage text not null
    check (stage in ('quarterfinal', 'semifinal', 'final')),
  position int not null check (position > 0),
  home_team_id uuid references public.teams (id) on delete set null,
  away_team_id uuid references public.teams (id) on delete set null,
  match_id uuid references public.matches (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (tournament_id, stage, position)
);

create index if not exists tournament_slots_tournament_idx
  on public.tournament_slots (tournament_id);

alter table public.tournament_slots enable row level security;

drop policy if exists "tournament_slots_select_authenticated"
  on public.tournament_slots;
create policy "tournament_slots_select_authenticated"
  on public.tournament_slots for select to authenticated using (true);

drop policy if exists "tournament_slots_insert_admin" on public.tournament_slots;
create policy "tournament_slots_insert_admin"
  on public.tournament_slots for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "tournament_slots_update_admin" on public.tournament_slots;
create policy "tournament_slots_update_admin"
  on public.tournament_slots for update to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "tournament_slots_delete_admin" on public.tournament_slots;
create policy "tournament_slots_delete_admin"
  on public.tournament_slots for delete to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- Solo el administrador dirige partidos
-- ---------------------------------------------------------------------------
drop policy if exists "matches_insert_own" on public.matches;
drop policy if exists "matches_insert_admin" on public.matches;
create policy "matches_insert_admin"
  on public.matches for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
