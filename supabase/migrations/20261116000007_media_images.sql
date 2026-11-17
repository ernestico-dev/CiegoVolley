-- CiegoVolley · fotos de equipos e imágenes de torneos
-- Ejecútalo después de 20261116000006_match_sets.sql.

-- ---------------------------------------------------------------------------
-- Imagen del torneo (los equipos ya tienen `logo_url` desde el inicio)
-- ---------------------------------------------------------------------------
alter table public.tournaments
  add column if not exists image_url text;

-- ---------------------------------------------------------------------------
-- Bucket público para logos de equipos e imágenes de torneos
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

drop policy if exists "media_read" on storage.objects;
create policy "media_read"
  on storage.objects for select
  using (bucket_id = 'media');

-- El creador del equipo manda en `teams/<teamId>/…` y el administrador en
-- `tournaments/<tournamentId>/…`.
drop policy if exists "media_insert" on storage.objects;
create policy "media_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (
      (
        (storage.foldername(name))[1] = 'teams'
        and exists (
          select 1 from public.teams t
          where t.id::text = (storage.foldername(name))[2]
            and t.owner_id = auth.uid()
        )
      )
      or (
        (storage.foldername(name))[1] = 'tournaments'
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
    )
  );

drop policy if exists "media_update" on storage.objects;
create policy "media_update"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'media'
    and (
      (
        (storage.foldername(name))[1] = 'teams'
        and exists (
          select 1 from public.teams t
          where t.id::text = (storage.foldername(name))[2]
            and t.owner_id = auth.uid()
        )
      )
      or (
        (storage.foldername(name))[1] = 'tournaments'
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
    )
  )
  with check (
    bucket_id = 'media'
    and (
      (
        (storage.foldername(name))[1] = 'teams'
        and exists (
          select 1 from public.teams t
          where t.id::text = (storage.foldername(name))[2]
            and t.owner_id = auth.uid()
        )
      )
      or (
        (storage.foldername(name))[1] = 'tournaments'
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
    )
  );

drop policy if exists "media_delete" on storage.objects;
create policy "media_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'media'
    and (
      (
        (storage.foldername(name))[1] = 'teams'
        and exists (
          select 1 from public.teams t
          where t.id::text = (storage.foldername(name))[2]
            and t.owner_id = auth.uid()
        )
      )
      or (
        (storage.foldername(name))[1] = 'tournaments'
        and exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
    )
  );
