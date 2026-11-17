-- Añade resultados neutrales y bloqueados para aplicar las fórmulas oficiales
-- de efectividad de saque, ataque, defensa y bloqueo.
alter table public.match_player_stats
  add column if not exists neutrals int not null default 0 check (neutrals >= 0),
  add column if not exists blocked int not null default 0 check (blocked >= 0);
