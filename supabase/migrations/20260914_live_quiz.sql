-- Live quiz : un formateur/admin déclenche un quiz de la banque,
-- qui apparaît instantanément (via Realtime) chez tous les membres connectés.
--
-- ⚠️ Ce fichier suppose une table de rôle nommée `users` avec une colonne
-- `role` contenant 'formateur' / 'admin' / 'membre'. Si ton schéma existant
-- utilise un autre nom (ex. `profiles`), remplace `users` par le bon nom
-- dans les 5 policies "_staff" ci-dessous avant d'exécuter.

-- Banque de quiz réutilisable (placement, révisions, live...)
create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  position int not null default 0,
  statement text not null,
  created_at timestamptz not null default now()
);

create table if not exists quiz_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references quiz_questions(id) on delete cascade,
  label text not null,
  is_correct boolean not null default false
);

-- Une ligne = un déclenchement du bouton "Lancer un quiz"
create table if not exists live_quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id),
  status text not null default 'active' check (status in ('active', 'closed')),
  started_by uuid not null references auth.users(id),
  started_at timestamptz not null default now(),
  closed_at timestamptz
);

-- Un seul quiz live actif à la fois dans toute l'appli
create unique index if not exists one_active_live_quiz
  on live_quiz_sessions (status)
  where status = 'active';

create table if not exists live_quiz_responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_quiz_sessions(id) on delete cascade,
  question_id uuid not null references quiz_questions(id),
  user_id uuid not null references auth.users(id),
  option_id uuid not null references quiz_options(id),
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  unique (session_id, question_id, user_id)
);

alter table quizzes enable row level security;
alter table quiz_questions enable row level security;
alter table quiz_options enable row level security;
alter table live_quiz_sessions enable row level security;
alter table live_quiz_responses enable row level security;

-- Lecture ouverte à tout utilisateur connecté (banque + sessions)
create policy "quizzes_select_authenticated" on quizzes
  for select to authenticated using (true);

create policy "quiz_questions_select_authenticated" on quiz_questions
  for select to authenticated using (true);

create policy "quiz_options_select_authenticated" on quiz_options
  for select to authenticated using (true);

create policy "live_quiz_sessions_select_authenticated" on live_quiz_sessions
  for select to authenticated using (true);

-- Écriture sur la banque de quiz réservée formateur/admin
create policy "quizzes_write_staff" on quizzes
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "quiz_questions_write_staff" on quiz_questions
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "quiz_options_write_staff" on quiz_options
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

-- Déclenchement / fermeture d'une session live réservés formateur/admin
create policy "live_quiz_sessions_insert_staff" on live_quiz_sessions
  for insert to authenticated
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "live_quiz_sessions_update_staff" on live_quiz_sessions
  for update to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

-- Réponses : chacun écrit/lit les siennes, le staff peut tout lire
create policy "live_quiz_responses_insert_own" on live_quiz_responses
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "live_quiz_responses_select_own_or_staff" on live_quiz_responses
  for select to authenticated
  using (
    auth.uid() = user_id
    or exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin'))
  );

-- Realtime : c'est cette ligne qui permet au popup d'apparaître
-- instantanément chez tout le monde dès l'insertion d'une session 'active'.
alter publication supabase_realtime add table live_quiz_sessions;
