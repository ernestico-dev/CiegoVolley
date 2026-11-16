-- CiegoVolley · rol de administrador y gestión de torneos
-- Ejecútalo después de 20261116000000_team_members_tournaments.sql.

-- ---------------------------------------------------------------------------
-- Rol del usuario
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists role text not null default 'member';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('member', 'admin'));
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Administrador del club: Ernesto Carbonel
-- ---------------------------------------------------------------------------
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = 'ecpkiko2002@gmail.com';

-- Si el correo no coincide, se busca por nombre.
do $$
begin
  if not exists (select 1 from public.profiles where role = 'admin') then
    update public.profiles
    set role = 'admin'
    where full_name ilike '%carbonel%';
  end if;

  if not exists (select 1 from public.profiles where role = 'admin') then
    raise notice 'No se encontró ningún administrador: revisa el correo o el nombre.';
  end if;
end;
$$;

-- Un usuario no puede ascenderse a sí mismo: solo un admin cambia roles.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and auth.uid() is not null then
    if not exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    ) then
      raise exception 'Solo un administrador puede cambiar roles.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
  before update of role on public.profiles
  for each row execute function public.protect_profile_role();

-- ---------------------------------------------------------------------------
-- Torneos: solo el administrador crea, edita y elimina
-- ---------------------------------------------------------------------------
drop policy if exists "tournaments_insert_own" on public.tournaments;
drop policy if exists "tournaments_update_own" on public.tournaments;
drop policy if exists "tournaments_delete_own" on public.tournaments;

drop policy if exists "tournaments_insert_admin" on public.tournaments;
create policy "tournaments_insert_admin"
  on public.tournaments for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "tournaments_update_admin" on public.tournaments;
create policy "tournaments_update_admin"
  on public.tournaments for update to authenticated
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

drop policy if exists "tournaments_delete_admin" on public.tournaments;
create policy "tournaments_delete_admin"
  on public.tournaments for delete to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
