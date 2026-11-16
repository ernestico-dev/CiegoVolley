-- CiegoVolley · modo partido: partidos y estadísticas por jugador
-- Ejecútalo después de 20261116000001_tournament_admin.sql.

-- ---------------------------------------------------------------------------
-- Partidos
-- ---------------------------------------------------------------------------
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments (id) on delete cascade,
  home_team_id uuid not null references public.teams (id) on delete cascade,
  away_team_id uuid not null references public.teams (id) on delete cascade,
  home_score int not null default 0 check (home_score >= 0),
  away_score int not null default 0 check (away_score >= 0),
  status text not null default 'finished'
    check (status in ('live', 'finished')),
  created_by uuid not null references public.profiles (id) on delete cascade,
  played_at timestamptz not null default now(),
  constraint matches_distinct_teams check (home_team_id <> away_team_id)
);

create index if not exists matches_tournament_idx
  on public.matches (tournament_id);
create index if not exists matches_created_by_idx
  on public.matches (created_by);

alter table public.matches enable row level security;

drop policy if exists "matches_select_authenticated" on public.matches;
create policy "matches_select_authenticated"
  on public.matches for select to authenticated using (true);

drop policy if exists "matches_insert_own" on public.matches;
create policy "matches_insert_own"
  on public.matches for insert to authenticated
  with check (auth.uid() = created_by);

drop policy if exists "matches_update_own" on public.matches;
create policy "matches_update_own"
  on public.matches for update to authenticated
  using (auth.uid() = created_by) with check (auth.uid() = created_by);

drop policy if exists "matches_delete_own" on public.matches;
create policy "matches_delete_own"
  on public.matches for delete to authenticated
  using (auth.uid() = created_by);

-- ---------------------------------------------------------------------------
-- Estadísticas por jugador y acción
-- ---------------------------------------------------------------------------
create table if not exists public.match_player_stats (
  match_id uuid not null references public.matches (id) on delete cascade,
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  action text not null
    check (action in ('serve', 'attack', 'defense', 'block')),
  successes int not null default 0 check (successes >= 0),
  failures int not null default 0 check (failures >= 0),
  primary key (match_id, user_id, action)
);

create index if not exists match_player_stats_user_idx
  on public.match_player_stats (user_id);

alter table public.match_player_stats enable row level security;

drop policy if exists "match_player_stats_select_authenticated"
  on public.match_player_stats;
create policy "match_player_stats_select_authenticated"
  on public.match_player_stats for select to authenticated using (true);

drop policy if exists "match_player_stats_insert_match_owner"
  on public.match_player_stats;
create policy "match_player_stats_insert_match_owner"
  on public.match_player_stats for insert to authenticated
  with check (
    exists (
      select 1 from public.matches m
      where m.id = match_player_stats.match_id
        and m.created_by = auth.uid()
    )
  );

drop policy if exists "match_player_stats_update_match_owner"
  on public.match_player_stats;
create policy "match_player_stats_update_match_owner"
  on public.match_player_stats for update to authenticated
  using (
    exists (
      select 1 from public.matches m
      where m.id = match_player_stats.match_id
        and m.created_by = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.matches m
      where m.id = match_player_stats.match_id
        and m.created_by = auth.uid()
    )
  );

drop policy if exists "match_player_stats_delete_match_owner"
  on public.match_player_stats;
create policy "match_player_stats_delete_match_owner"
  on public.match_player_stats for delete to authenticated
  using (
    exists (
      select 1 from public.matches m
      where m.id = match_player_stats.match_id
        and m.created_by = auth.uid()
    )
  );
