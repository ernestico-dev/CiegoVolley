-- CiegoVolley · el creador del equipo entra como integrante
-- Ejecútalo después de 20261116000002_matches.sql.

-- Cualquier equipo nuevo añade a su creador como jugador.
create or replace function public.add_team_owner_as_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.team_members (team_id, user_id, role)
  values (new.id, new.owner_id, 'player')
  on conflict (team_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists add_team_owner_as_member on public.teams;
create trigger add_team_owner_as_member
  after insert on public.teams
  for each row execute function public.add_team_owner_as_member();

-- Equipos que ya existían: mete al creador si no estaba.
insert into public.team_members (team_id, user_id, role)
select t.id, t.owner_id, 'player'
from public.teams t
where not exists (
  select 1 from public.team_members m
  where m.team_id = t.id and m.user_id = t.owner_id
)
on conflict (team_id, user_id) do nothing;
