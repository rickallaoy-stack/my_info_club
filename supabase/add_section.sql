-- =========================================================
-- SUPABASE: Sections — migration pour l'intégration sections
-- À exécuter dans Supabase > SQL Editor.
-- Table réelle : public.users (clé `id` = auth.users.id)
-- =========================================================

-- 1. Enum pour les sections
do $$
begin
  create type public.club_section as enum (
    'cybersecurite',
    'iot',
    'dev-web',
    'dev-mobile',
    'ia-automatisation'
  );
exception
  when duplicate_object then null;
end $$;

-- 2. Ajouter la colonne section à public.users
alter table public.users
  add column if not exists section public.club_section;

-- 3. Index pour les requêtes par section
create index if not exists idx_users_section on public.users(section);

-- 4. Vérifie la politique RLS d'UPDATE sur users.
-- Elle doit permettre à un membre de modifier SA ligne (auth.uid() = id),
-- mais il ne doit pas pouvoir changer sa colonne de rôle/groupe
-- (sinon un membre pourrait se donner le rôle formateur ou admin).
-- Solution : trigger trg_prevent_privileged_self_update (voir rls_poolicie.sql)
-- bloque déjà role, class_id, current_level_id pour non-admin.
-- La colonne section reste modifiable par l'utilisateur.

-- 5. Politique SELECT sur users : déjà couverte par users_select dans rls_poolicie.sql
-- (un utilisateur voit sa ligne, admin voit tout, formateur voit ses étudiants)