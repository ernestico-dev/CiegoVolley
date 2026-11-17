-- CiegoVolley · limpieza de resultados de acciones
--
-- Las acciones se guardan solo como aciertos y fallos. Un ataque bloqueado es
-- un fallo de ataque para quien ataca y un acierto de bloqueo para quien
-- bloquea. Si una versión anterior añadió columnas de neutros o bloqueados,
-- se eliminan para que no influyan en las fórmulas.

alter table public.match_player_stats
  drop column if exists neutrals,
  drop column if exists blocked;
