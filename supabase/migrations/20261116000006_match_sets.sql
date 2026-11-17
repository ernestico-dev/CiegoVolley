-- CiegoVolley · partidos por sets
-- Ejecútalo después de 20261116000005_avatars_notifications.sql.

-- Cuántos sets tiene el partido: solo 1, 3 o 5.
alter table public.matches
  add column if not exists sets_count int not null default 1;

-- Puntos de cada set terminado: [{"home": 25, "away": 20}, …].
alter table public.matches
  add column if not exists sets jsonb not null default '[]'::jsonb;

-- Se juega al mejor de 1, 3 o 5: nunca hay empate.
alter table public.matches
  drop constraint if exists matches_sets_count_check;
alter table public.matches
  add constraint matches_sets_count_check
  check (sets_count in (1, 3, 5));
