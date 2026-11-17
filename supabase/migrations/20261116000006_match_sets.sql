-- CiegoVolley · partidos por sets
-- Ejecútalo después de 20261116000005_avatars_notifications.sql.

-- Cuántos sets tiene el partido (1 a 5).
alter table public.matches
  add column if not exists sets_count int not null default 1;

-- Puntos de cada set terminado: [{"home": 25, "away": 20}, …].
alter table public.matches
  add column if not exists sets jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'matches_sets_count_check'
      and conrelid = 'public.matches'::regclass
  ) then
    alter table public.matches
      add constraint matches_sets_count_check
      check (sets_count between 1 and 5);
  end if;
end;
$$;
