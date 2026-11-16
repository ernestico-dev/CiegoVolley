-- Torneos de ejemplo para poder probar la inscripción de equipos.
-- Ejecútalo en el SQL Editor después de las migraciones.

insert into public.tournaments (owner_id, name, venue, starts_on, ends_on, status)
select u.id, t.name, t.venue, t.starts_on, t.ends_on, 'published'
from (select id from auth.users order by created_at limit 1) u
cross join (
  values
    ('Liga Provincial 2026', 'Ciego de Ávila', date '2026-12-01', date '2026-12-15'),
    ('Copa de Invierno', 'Morón', date '2027-01-10', date '2027-01-12'),
    ('Torneo de Fin de Año', 'Ciego de Ávila', date '2026-12-27', date '2026-12-29')
) as t(name, venue, starts_on, ends_on)
where not exists (
  select 1 from public.tournaments x where x.name = t.name
);
