-- =========================================================
-- SUPABASE: Placement Quiz par section
-- À exécuter APRÈS add_section.sql
-- =========================================================

-- 1. Ajouter la colonne section à placement_quizzes
alter table public.placement_quizzes
  add column if not exists section public.club_section;

-- 2. Index pour les requêtes par section
create index if not exists idx_placement_quizzes_section on public.placement_quizzes(section);

-- 3. Politique SELECT : lecture ouverte pour utilisateurs connectés
drop policy if exists placement_quizzes_select on public.placement_quizzes;
create policy placement_quizzes_select on public.placement_quizzes
for select using (auth.uid() is not null);

-- 4. Politique WRITE : admin/trainer uniquement
drop policy if exists placement_quizzes_write on public.placement_quizzes;
create policy placement_quizzes_write on public.placement_quizzes
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

-- Note : Les questions et options héritent de la section via le quiz.
-- RLS existantes sur placement_questions/options restent valides.