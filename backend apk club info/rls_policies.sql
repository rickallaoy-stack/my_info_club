-- =========================================================
-- PLATEFORME DU CLUB INFORMATIQUE — POLICIES RLS (MISE À JOUR)
-- À exécuter APRÈS schema.sql ET add_section.sql
-- Inclut : isolation par section pour formateurs, UPDATE restreint sur users
-- =========================================================

-- =========================================================
-- FONCTIONS HELPERS
-- =========================================================

-- Rôle de l'utilisateur courant
create or replace function public.current_role()
returns user_role
language sql stable
security definer
as $$
  select role from public.users where id = auth.uid();
$$;

-- L'utilisateur courant est-il formateur de cette classe ?
create or replace function public.is_trainer_of_class(cid uuid)
returns boolean
language sql stable
security definer
as $$
  select exists (
    select 1 from public.class_trainers ct
    where ct.class_id = cid and ct.user_id = auth.uid()
  );
$$;

-- L'utilisateur courant est-il membre de cette classe ?
create or replace function public.is_member_of_class(cid uuid)
returns boolean
language sql stable
security definer
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.class_id = cid
  );
$$;

-- Section de l'utilisateur courant
create or replace function public.current_section()
returns club_section
language sql stable
security definer
as $$
  select section from public.users where id = auth.uid();
$$;

-- L'utilisateur courant est-il formateur de cette section ?
create or replace function public.is_trainer_of_section(sec club_section)
returns boolean
language sql stable
security definer
as $$
  select public.current_role() = 'trainer' and public.current_section() = sec;
$$;

-- =========================================================
-- TRIGGER DE SECURITE: empêche un membre de s'auto-promouvoir
-- (role, class_id, current_level_id réservés à admin / triggers système)
-- =========================================================
create or replace function public.prevent_privileged_self_update()
returns trigger as $$
begin
  if public.current_role() <> 'admin' then
    if new.role is distinct from old.role then
      raise exception 'Modification du rôle interdite';
    end if;
    if new.class_id is distinct from old.class_id then
      raise exception 'Modification de la classe interdite';
    end if;
    if new.current_level_id is distinct from old.current_level_id then
      raise exception 'Modification du niveau interdite';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_prevent_privileged_self_update on public.users;
create trigger trg_prevent_privileged_self_update
before update on public.users
for each row execute function public.prevent_privileged_self_update();

-- =========================================================
-- USERS
-- =========================================================
drop policy if exists users_select on public.users;
create policy users_select on public.users
for select using (
  id = auth.uid()
  or public.current_role() = 'admin'
  or (public.current_role() = 'trainer' and public.is_trainer_of_class(class_id))
  or (public.current_role() = 'trainer' and public.is_trainer_of_section(section))
);

drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users
for update using (id = auth.uid() or public.current_role() = 'admin')
with check (id = auth.uid() or public.current_role() = 'admin');
-- Note: le trigger trg_prevent_privileged_self_update bloque le changement
-- de role/class_id/current_level_id par un non-admin, même si cette policy passe.
-- Colonnes modifiables par l'utilisateur : nom, prenom, email, section, avatar_url, etc.

-- =========================================================
-- SECTIONS
-- =========================================================
drop policy if exists sections_select on public.sections;
create policy sections_select on public.sections
for select using (auth.uid() is not null);

drop policy if exists sections_write on public.sections;
create policy sections_write on public.sections
for all using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

-- =========================================================
-- CLASSES
-- =========================================================
drop policy if exists classes_select on public.classes;
create policy classes_select on public.classes
for select using (auth.uid() is not null);

drop policy if exists classes_write on public.classes;
create policy classes_write on public.classes
for all using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

-- =========================================================
-- CLASS_TRAINERS
-- =========================================================
drop policy if exists class_trainers_select on public.class_trainers;
create policy class_trainers_select on public.class_trainers
for select using (auth.uid() is not null);

drop policy if exists class_trainers_write on public.class_trainers;
create policy class_trainers_write on public.class_trainers
for all using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

-- =========================================================
-- LEARNING_PATHS / LEVELS / SKILLS
-- =========================================================
drop policy if exists learning_paths_select on public.learning_paths;
create policy learning_paths_select on public.learning_paths
for select using (auth.uid() is not null);

drop policy if exists learning_paths_write on public.learning_paths;
create policy learning_paths_write on public.learning_paths
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

drop policy if exists levels_select on public.levels;
create policy levels_select on public.levels
for select using (auth.uid() is not null);

drop policy if exists levels_write on public.levels;
create policy levels_write on public.levels
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

drop policy if exists skills_select on public.skills;
create policy skills_select on public.skills
for select using (auth.uid() is not null);

drop policy if exists skills_write on public.skills;
create policy skills_write on public.skills
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

-- =========================================================
-- ACTIVITIES
-- =========================================================
drop policy if exists activities_select on public.activities;
create policy activities_select on public.activities
for select using (
  public.current_role() = 'admin'
  or public.is_trainer_of_class(class_id)
  or public.is_member_of_class(class_id)
);

drop policy if exists activities_write on public.activities;
create policy activities_write on public.activities
for all using (
  public.current_role() = 'admin' or public.is_trainer_of_class(class_id)
)
with check (
  public.current_role() = 'admin' or public.is_trainer_of_class(class_id)
);

-- =========================================================
-- SUBMISSIONS
-- =========================================================
drop policy if exists submissions_select on public.submissions;
create policy submissions_select on public.submissions
for select using (
  user_id = auth.uid()
  or public.current_role() = 'admin'
  or exists (
    select 1 from public.activities a
    where a.id = activity_id and public.is_trainer_of_class(a.class_id)
  )
);

drop policy if exists submissions_insert on public.submissions;
create policy submissions_insert on public.submissions
for insert with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.activities a
    where a.id = activity_id and public.is_member_of_class(a.class_id)
  )
);

drop policy if exists submissions_update on public.submissions;
create policy submissions_update on public.submissions
for update using (
  public.current_role() = 'admin'
  or exists (
    select 1 from public.activities a
    where a.id = activity_id and public.is_trainer_of_class(a.class_id)
  )
)
with check (
  public.current_role() = 'admin'
  or exists (
    select 1 from public.activities a
    where a.id = activity_id and public.is_trainer_of_class(a.class_id)
  )
);

-- =========================================================
-- EVALUATIONS
-- =========================================================
drop policy if exists evaluations_select on public.evaluations;
create policy evaluations_select on public.evaluations
for select using (
  public.current_role() = 'admin'
  or evaluateur_id = auth.uid()
  or exists (
    select 1 from public.submissions s
    where s.id = submission_id and s.user_id = auth.uid()
  )
);

drop policy if exists evaluations_insert on public.evaluations;
create policy evaluations_insert on public.evaluations
for insert with check (
  public.current_role() = 'admin'
  or (
    evaluateur_id = auth.uid()
    and exists (
      select 1 from public.submissions s
      join public.activities a on a.id = s.activity_id
      where s.id = submission_id and public.is_trainer_of_class(a.class_id)
    )
  )
);

-- =========================================================
-- SKILL_VALIDATIONS
-- =========================================================
drop policy if exists skill_validations_select on public.skill_validations;
create policy skill_validations_select on public.skill_validations
for select using (
  user_id = auth.uid()
  or public.current_role() = 'admin'
  or validateur_id = auth.uid()
);

drop policy if exists skill_validations_insert on public.skill_validations;
create policy skill_validations_insert on public.skill_validations
for insert with check (
  public.current_role() = 'admin'
  or (public.current_role() = 'trainer' and validateur_id = auth.uid())
);

-- =========================================================
-- SESSIONS
-- =========================================================
drop policy if exists sessions_select on public.sessions;
create policy sessions_select on public.sessions
for select using (
  public.current_role() = 'admin'
  or public.is_trainer_of_class(class_id)
  or public.is_member_of_class(class_id)
);

drop policy if exists sessions_write on public.sessions;
create policy sessions_write on public.sessions
for all using (
  public.current_role() = 'admin' or public.is_trainer_of_class(class_id)
)
with check (
  public.current_role() = 'admin' or public.is_trainer_of_class(class_id)
);

-- =========================================================
-- ATTENDANCE
-- =========================================================
drop policy if exists attendance_select on public.attendance;
create policy attendance_select on public.attendance
for select using (
  user_id = auth.uid()
  or public.current_role() = 'admin'
  or exists (
    select 1 from public.sessions se
    where se.id = session_id and public.is_trainer_of_class(se.class_id)
  )
);

drop policy if exists attendance_write on public.attendance;
create policy attendance_write on public.attendance
for all using (
  public.current_role() = 'admin'
  or exists (
    select 1 from public.sessions se
    where se.id = session_id and public.is_trainer_of_class(se.class_id)
  )
)
with check (
  public.current_role() = 'admin'
  or exists (
    select 1 from public.sessions se
    where se.id = session_id and public.is_trainer_of_class(se.class_id)
  )
);

-- =========================================================
-- POINTS DE COMPETENCES
-- =========================================================
drop policy if exists competency_points_select on public.competency_points;
create policy competency_points_select on public.competency_points
for select using (
  user_id = auth.uid()
  or public.current_role() = 'admin'
  or (public.current_role() = 'trainer' and exists (
    select 1 from public.users student
    where student.id = user_id
      and public.is_trainer_of_class(student.class_id)
  ))
  or (public.current_role() = 'trainer' and exists (
    select 1 from public.users student
    where student.id = user_id
      and public.is_trainer_of_section(student.section)
  ))
);

drop policy if exists competency_points_insert on public.competency_points;
create policy competency_points_insert on public.competency_points
for insert with check (
  (public.current_role() = 'admin' or public.current_role() = 'trainer')
  and trainer_id = auth.uid()
  and exists (
    select 1 from public.users student
    where student.id = user_id
      and (
        public.is_trainer_of_class(student.class_id)
        or public.is_trainer_of_section(student.section)
      )
  )
);

-- =========================================================
-- PLACEMENT QUIZ
-- =========================================================
drop policy if exists placement_quizzes_select on public.placement_quizzes;
create policy placement_quizzes_select on public.placement_quizzes
for select using (auth.uid() is not null);

drop policy if exists placement_quizzes_write on public.placement_quizzes;
create policy placement_quizzes_write on public.placement_quizzes
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

drop policy if exists placement_questions_select on public.placement_questions;
create policy placement_questions_select on public.placement_questions
for select using (auth.uid() is not null);

drop policy if exists placement_questions_write on public.placement_questions;
create policy placement_questions_write on public.placement_questions
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

drop policy if exists placement_options_select on public.placement_options;
create policy placement_options_select on public.placement_options
for select using (public.current_role() in ('admin', 'trainer'));

drop policy if exists placement_options_write on public.placement_options;
create policy placement_options_write on public.placement_options
for all using (public.current_role() in ('admin', 'trainer'))
with check (public.current_role() in ('admin', 'trainer'));

-- =========================================================
-- PLACEMENT ATTEMPTS / ANSWERS
-- =========================================================
drop policy if exists placement_attempts_select on public.placement_attempts;
create policy placement_attempts_select on public.placement_attempts
for select using (
  user_id = auth.uid() or public.current_role() in ('admin', 'trainer')
);

drop policy if exists placement_attempts_insert on public.placement_attempts;
create policy placement_attempts_insert on public.placement_attempts
for insert with check (user_id = auth.uid());

drop policy if exists placement_attempts_update on public.placement_attempts;
create policy placement_attempts_update on public.placement_attempts
for update using (
  user_id = auth.uid() or public.current_role() in ('admin', 'trainer')
)
with check (
  user_id = auth.uid() or public.current_role() in ('admin', 'trainer')
);

drop policy if exists placement_answers_select on public.placement_answers;
create policy placement_answers_select on public.placement_answers
for select using (
  exists (
    select 1 from public.placement_attempts pa
    where pa.id = attempt_id
      and (pa.user_id = auth.uid() or public.current_role() in ('admin', 'trainer'))
  )
);

drop policy if exists placement_answers_insert on public.placement_answers;
create policy placement_answers_insert on public.placement_answers
for insert with check (
  exists (
    select 1 from public.placement_attempts pa
    where pa.id = attempt_id and pa.user_id = auth.uid()
  )
);

-- =========================================================
-- VUE LEADERBOARD: respecter la RLS de l'utilisateur qui interroge
-- =========================================================
alter view public.leaderboard set (security_invoker = on);