-- =========================================================
-- PLATEFORME DU CLUB INFORMATIQUE — STORAGE
-- A exécuter APRES schema.sql et rls_policies.sql
-- =========================================================

-- =========================================================
-- BUCKET: avatars (public en lecture)
-- Convention de chemin: <user_id>/<nom_fichier>
-- =========================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists avatars_select on storage.objects;
create policy avatars_select on storage.objects
for select using (bucket_id = 'avatars');

drop policy if exists avatars_insert on storage.objects;
create policy avatars_insert on storage.objects
for insert with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects
for update using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists avatars_delete on storage.objects;
create policy avatars_delete on storage.objects
for delete using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- =========================================================
-- BUCKET: submissions (privé)
-- Convention de chemin: <user_id>/<nom_fichier>
-- =========================================================
insert into storage.buckets (id, name, public)
values ('submissions', 'submissions', false)
on conflict (id) do nothing;

-- Lecture: le membre propriétaire, le formateur de la classe concernée, ou l'admin
drop policy if exists submissions_files_select on storage.objects;
create policy submissions_files_select on storage.objects
for select using (
  bucket_id = 'submissions'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.current_role() = 'admin'
    or exists (
      select 1
      from public.submissions s
      join public.activities a on a.id = s.activity_id
      where s.user_id::text = (storage.foldername(name))[1]
        and public.is_trainer_of_class(a.class_id)
    )
  )
);

-- Ecriture: uniquement dans son propre dossier
drop policy if exists submissions_files_insert on storage.objects;
create policy submissions_files_insert on storage.objects
for insert with check (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists submissions_files_update on storage.objects;
create policy submissions_files_update on storage.objects
for update using (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists submissions_files_delete on storage.objects;
create policy submissions_files_delete on storage.objects
for delete using (
  bucket_id = 'submissions'
  and (storage.foldername(name))[1] = auth.uid()::text
);