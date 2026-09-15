-- =========================================================
-- PLATEFORME DU CLUB INFORMATIQUE — SCHEMA V1 (Mobile)
-- Backend: Supabase / PostgreSQL
-- Auteur: Développeur A (Backend / Données)
-- =========================================================

-- ---------- EXTENSIONS ----------
create extension if not exists "pgcrypto"; -- pour gen_random_uuid()

-- ---------- ENUMS ----------
create type user_role as enum ('member', 'trainer', 'admin');
create type submission_status as enum ('pending', 'reviewed', 'validated', 'rejected');
create type session_type as enum ('cours', 'atelier', 'evaluation');

-- =========================================================
-- 1. UTILISATEURS
-- =========================================================
-- Etend auth.users (Supabase Auth gère déjà id, email, password)
-- Note: class_id est ajouté après la création de public.classes (voir plus bas),
-- car un membre n'appartient qu'à UNE SEULE classe à la fois (pas de many-to-many).
create table public.users (
    id          uuid primary key references auth.users(id) on delete cascade,
    nom         text not null,
    prenom      text not null,
    email       text not null unique,
    role        user_role not null default 'member',
    avatar_url  text,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

alter table public.users
    add column privacy_policy_version text,
    add column terms_version text,
    add column consented_at timestamptz;

-- =========================================================
-- 2. SECTIONS
-- =========================================================
create table public.sections (
    id          uuid primary key default gen_random_uuid(),
    nom         text not null unique,
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 3. CLASSES
-- =========================================================
create table public.classes (
    id          uuid primary key default gen_random_uuid(),
    section_id  uuid not null references public.sections(id) on delete cascade,
    nom         text not null,
    date_debut  date not null,
    date_fin    date,
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 4. RATTACHEMENT D'UN MEMBRE A SA CLASSE ACTUELLE
-- =========================================================
-- Un membre n'appartient qu'à UNE seule classe à la fois.
-- La classe change au fil des années (passage en classe supérieure) ;
-- aucun historique des classes précédentes n'est conservé (choix assumé).
alter table public.users
    add column class_id uuid references public.classes(id) on delete set null;

create index idx_users_class on public.users(class_id);

-- =========================================================
-- 5. FORMATEURS DES CLASSES (table de liaison)
-- =========================================================
create table public.class_trainers (
    class_id    uuid not null references public.classes(id) on delete cascade,
    user_id     uuid not null references public.users(id) on delete cascade,
    assigned_at timestamptz not null default now(),
    primary key (class_id, user_id)
);

-- =========================================================
-- 6. PARCOURS D'APPRENTISSAGE
-- =========================================================
create table public.learning_paths (
    id          uuid primary key default gen_random_uuid(),
    nom         text not null,
    description text,
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 7. NIVEAUX
-- =========================================================
create table public.levels (
    id                uuid primary key default gen_random_uuid(),
    learning_path_id  uuid not null references public.learning_paths(id) on delete cascade,
    nom               text not null,
    ordre             int not null,
    unique (learning_path_id, ordre)
);

-- Niveau courant du membre dans son parcours, déterminé au départ par
-- le quiz de placement (voir section 15), puis mis à jour par sa progression.
alter table public.users
    add column current_level_id uuid references public.levels(id) on delete set null;

create index idx_users_level on public.users(current_level_id);

-- =========================================================
-- 8. COMPETENCES
-- =========================================================
create table public.skills (
    id          uuid primary key default gen_random_uuid(),
    level_id    uuid not null references public.levels(id) on delete cascade,
    nom         text not null,
    criteres    text,
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 9. ACTIVITES
-- =========================================================
create table public.activities (
    id          uuid primary key default gen_random_uuid(),
    class_id    uuid not null references public.classes(id) on delete cascade,
    skill_id    uuid references public.skills(id) on delete set null,
    titre       text not null,
    description text,
    echeance    timestamptz,
    created_by  uuid not null references public.users(id),
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 10. REMISES (SUBMISSIONS)
-- =========================================================
create table public.submissions (
    id              uuid primary key default gen_random_uuid(),
    activity_id     uuid not null references public.activities(id) on delete cascade,
    user_id         uuid not null references public.users(id) on delete cascade,
    github_url      text,
    fichier_url     text,           -- lien Supabase Storage
    declaration_ia  boolean not null default false,
    statut          submission_status not null default 'pending',
    submitted_at    timestamptz not null default now(),
    unique (activity_id, user_id)   -- une remise par membre et par activité
);

-- =========================================================
-- 11. EVALUATIONS
-- =========================================================
create table public.evaluations (
    id              uuid primary key default gen_random_uuid(),
    submission_id   uuid not null references public.submissions(id) on delete cascade,
    evaluateur_id   uuid not null references public.users(id),
    note            numeric(4,2),
    commentaire     text,
    created_at      timestamptz not null default now()
);

-- =========================================================
-- 12. VALIDATIONS DE COMPETENCES
-- =========================================================
create table public.skill_validations (
    id              uuid primary key default gen_random_uuid(),
    skill_id        uuid not null references public.skills(id) on delete cascade,
    user_id         uuid not null references public.users(id) on delete cascade,
    validateur_id   uuid not null references public.users(id),
    validated_at    timestamptz not null default now(),
    unique (skill_id, user_id)
);

-- =========================================================
-- 13. SEANCES
-- =========================================================
create table public.sessions (
    id          uuid primary key default gen_random_uuid(),
    class_id    uuid not null references public.classes(id) on delete cascade,
    date_seance date not null,
    type        session_type not null default 'cours',
    created_at  timestamptz not null default now()
);

-- =========================================================
-- 14. PRESENCES
-- =========================================================
create table public.attendance (
    session_id  uuid not null references public.sessions(id) on delete cascade,
    user_id     uuid not null references public.users(id) on delete cascade,
    present     boolean not null default false,
    primary key (session_id, user_id)
);

-- ---------- POINTS DE COMPETENCES ----------
-- Historise chaque attribution du formateur afin de conserver les preuves
-- de progression (exercices, réalisations et mini-hackathons).
create type competency_point_category as enum (
    'realisation',
    'comprehension_exercice',
    'mini_hackathon'
);

create table public.competency_points (
    id           uuid primary key default gen_random_uuid(),
    user_id      uuid not null references public.users(id) on delete cascade,
    trainer_id   uuid not null references public.users(id),
    category     competency_point_category not null,
    points       int not null check (points > 0 and points <= 100),
    commentaire  text,
    created_at   timestamptz not null default now()
);

create index idx_competency_points_user on public.competency_points(user_id);

create or replace function public.apply_competency_level()
returns trigger as $$
declare
    total_points int;
    target_level uuid;
begin
    select coalesce(sum(points), 0)
    into total_points
    from public.competency_points
    where user_id = new.user_id;

    select id into target_level
    from public.levels
    where lower(replace(replace(nom, 'é', 'e'), 'è', 'e')) = case
        when total_points >= 500 then 'expert'
        when total_points >= 250 then 'intermediaire'
        when total_points >= 100 then 'novice'
        else 'debutant'
    end
    order by ordre
    limit 1;

    if target_level is not null then
        update public.users
        set current_level_id = target_level
        where id = new.user_id;
    end if;
    return new;
end;
$$ language plpgsql security definer;

create trigger trg_apply_competency_level
after insert on public.competency_points
for each row execute function public.apply_competency_level();

-- =========================================================
-- INDEXES UTILES
-- =========================================================
create index idx_classes_section on public.classes(section_id);
create index idx_activities_class on public.activities(class_id);
create index idx_submissions_user on public.submissions(user_id);
create index idx_submissions_activity on public.submissions(activity_id);
create index idx_skill_validations_user on public.skill_validations(user_id);
create index idx_attendance_user on public.attendance(user_id);

-- =========================================================
-- TRIGGER: updated_at automatique sur users
-- =========================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- =========================================================
-- TRIGGER: création auto de la ligne public.users à l'inscription
-- =========================================================
create or replace function public.handle_new_auth_user()
returns trigger as $$
begin
  insert into public.users (
    id, nom, prenom, email, role,
    privacy_policy_version, terms_version, consented_at
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nom', ''),
    coalesce(new.raw_user_meta_data->>'prenom', ''),
    new.email,
    'member',
    case
      when (new.raw_user_meta_data->>'privacy_policy_accepted')::boolean
      then new.raw_user_meta_data->>'privacy_policy_version'
    end,
    case
      when (new.raw_user_meta_data->>'terms_accepted')::boolean
      then new.raw_user_meta_data->>'terms_version'
    end,
    case
      when (new.raw_user_meta_data->>'privacy_policy_accepted')::boolean
       and (new.raw_user_meta_data->>'terms_accepted')::boolean
      then now()
    end
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- =========================================================
-- 15. QUIZ DE PLACEMENT
-- =========================================================
-- Détermine le niveau initial d'un membre au premier login,
-- avant même toute activité réalisée dans son parcours.
create table public.placement_quizzes (
    id                uuid primary key default gen_random_uuid(),
    learning_path_id  uuid not null references public.learning_paths(id) on delete cascade,
    nom               text not null,
    created_at        timestamptz not null default now()
);

create table public.placement_questions (
    id          uuid primary key default gen_random_uuid(),
    quiz_id     uuid not null references public.placement_quizzes(id) on delete cascade,
    enonce      text not null,
    ordre       int not null,
    unique (quiz_id, ordre)
);

create table public.placement_options (
    id            uuid primary key default gen_random_uuid(),
    question_id   uuid not null references public.placement_questions(id) on delete cascade,
    texte         text not null,
    est_correcte  boolean not null default false
);

-- Une tentative = un passage complet du quiz par un membre.
create table public.placement_attempts (
    id                uuid primary key default gen_random_uuid(),
    quiz_id           uuid not null references public.placement_quizzes(id) on delete cascade,
    user_id           uuid not null references public.users(id) on delete cascade,
    score             numeric(5,2),
    result_level_id   uuid references public.levels(id) on delete set null,
    completed_at      timestamptz not null default now(),
    unique (quiz_id, user_id)   -- un seul passage de placement par membre
);

create table public.placement_answers (
    attempt_id    uuid not null references public.placement_attempts(id) on delete cascade,
    question_id   uuid not null references public.placement_questions(id) on delete cascade,
    option_id     uuid not null references public.placement_options(id),
    primary key (attempt_id, question_id)
);

-- Trigger: à chaque tentative de placement enregistrée (ou corrigée),
-- répercute automatiquement le niveau obtenu sur users.current_level_id.
create or replace function public.apply_placement_result()
returns trigger as $$
begin
  if new.result_level_id is not null then
    update public.users
    set current_level_id = new.result_level_id
    where id = new.user_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_apply_placement_result
after insert or update of result_level_id on public.placement_attempts
for each row execute function public.apply_placement_result();

-- =========================================================
-- 16. CLASSEMENT (RANKING)
-- =========================================================
-- Vue calculée à partir des compétences validées et des notes,
-- pas de table stockée : le classement reste toujours à jour
-- sans duplication de données ni tâche de synchronisation.
create view public.leaderboard as
select
    u.id                                as user_id,
    u.nom,
    u.prenom,
    u.class_id,
    count(distinct sv.skill_id)         as competences_validees,
    coalesce(avg(e.note), 0)            as moyenne_evaluations,
    rank() over (
        partition by u.class_id
        order by count(distinct sv.skill_id) desc, coalesce(avg(e.note), 0) desc
    ) as rang_classe
from public.users u
left join public.skill_validations sv on sv.user_id = u.id
left join public.submissions s on s.user_id = u.id
left join public.evaluations e on e.submission_id = s.id
where u.role = 'member'
group by u.id, u.nom, u.prenom, u.class_id;

-- =========================================================
-- ROW LEVEL SECURITY (activation — policies à affiner ensuite)
-- =========================================================
alter table public.users enable row level security;
alter table public.sections enable row level security;
alter table public.classes enable row level security;
alter table public.class_trainers enable row level security;
alter table public.learning_paths enable row level security;
alter table public.levels enable row level security;
alter table public.skills enable row level security;
alter table public.activities enable row level security;
alter table public.submissions enable row level security;
alter table public.evaluations enable row level security;
alter table public.skill_validations enable row level security;
alter table public.sessions enable row level security;
alter table public.attendance enable row level security;
alter table public.competency_points enable row level security;
alter table public.placement_quizzes enable row level security;
alter table public.placement_questions enable row level security;
alter table public.placement_options enable row level security;
alter table public.placement_attempts enable row level security;
alter table public.placement_answers enable row level security;