-- =========================================================
-- PLACEMENT : RPC submit_placement — CALCUL CÔTÉ SERVEUR UNIQUEMENT
-- À exécuter APRÈS schema.sql, add_section.sql, add_placement_section.sql
-- =========================================================

-- Fonction RPC : soumet les réponses, calcule le niveau, enregistre tout, retourne level_id
create or replace function public.submit_placement(
  p_quiz_id uuid,
  p_answers jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quiz_row record;
  v_user_section club_section;
  v_question_count int;
  v_correct_count int := 0;
  v_pct numeric;
  v_level_code text;
  v_level_id uuid;
  v_attempt_id uuid;
  v_answer jsonb;
  v_question_id uuid;
  v_option_id uuid;
begin
  -- 1. Utilisateur authentifié obligatoire
  if v_user_id is null then
    raise exception 'Non authentifié';
  end if;

  -- 2. Vérifier que le quiz existe et récupérer son learning_path_id + section
  select * into v_quiz_row
  from public.placement_quizzes
  where id = p_quiz_id;

  if not found then
    raise exception 'Quiz introuvable';
  end if;

  -- 3. Vérifier la section : le quiz doit correspondre à la section de l'utilisateur
  --    (ou le quiz n'a pas de section = quiz global)
  select section into v_user_section
  from public.users
  where id = v_user_id;

  if v_quiz_row.section is not null and v_quiz_row.section <> v_user_section then
    raise exception 'Quiz non autorisé pour votre section';
  end if;

  -- 4. Refuser si l'utilisateur a déjà un niveau (sauf admin)
  if exists (
    select 1 from public.users
    where id = v_user_id and current_level_id is not null and role <> 'admin'
  ) then
    raise exception 'Niveau déjà attribué';
  end if;

  -- 5. Compter les questions du quiz
  select count(*) into v_question_count
  from public.placement_questions
  where quiz_id = p_quiz_id;

  if v_question_count = 0 then
    raise exception 'Quiz sans questions';
  end if;

  -- 6. Valider et compter les bonnes réponses
  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    v_question_id := (v_answer->>'question_id')::uuid;
    v_option_id := (v_answer->>'option_id')::uuid;

    -- Vérifier que la question appartient au quiz
    if not exists (
      select 1 from public.placement_questions
      where id = v_question_id and quiz_id = p_quiz_id
    ) then
      raise exception 'Question % ne fait pas partie du quiz', v_question_id;
    end if;

    -- Vérifier que l'option appartient à la question
    if not exists (
      select 1 from public.placement_options
      where id = v_option_id and question_id = v_question_id
    ) then
      raise exception 'Option % invalide pour la question %', v_option_id, v_question_id;
    end if;

    -- Compter si correcte
    if exists (
      select 1 from public.placement_options
      where id = v_option_id and est_correcte = true
    ) then
      v_correct_count := v_correct_count + 1;
    end if;
  end loop;

  -- 7. Calculer le pourcentage
  v_pct := (v_correct_count::numeric / v_question_count) * 100;

  -- 8. Déterminer le code de niveau (SEUILS EXACTS de placement_quiz_screen.dart)
  -- Logique locale : correctAnswers (0-4) + surveyScore (1-2) => total 1-6
  -- Seuils : <=2 Débutant, <=4 Novice, <=6 Intermédiaire, >6 Expert
  -- En pourcentage sur les questions du quiz (sans sondage) :
  -- On reproduit la même logique : score = correctAnswers (entier) + surveyScore (0.5 à 2)
  -- Mais côté serveur on n'a pas le sondage -> on utilise uniquement correctAnswers
  -- Pour mapper les seuils locaux (2, 4, 6) sur un nombre de questions variable :
  --   total_local = correctAnswers + surveyScore (moyenne 1.5)
  --   seuils locaux : 2, 4, 6
  --   => correctAnswers_seuil = seuil - 1.5 ≈ 0.5, 2.5, 4.5
  -- On arrondit : Débutant si correctAnswers <= 1, Novice si <= 2, Intermédiaire si <= 3, Expert si >= 4
  -- MAIS le quiz a 4 questions dans l'exemple. Pour généraliser :
  --   On utilise des pourcentages équivalents :
  --   total_local max = 4 + 2 = 6
  --   Débutant : <= 2/6 = 33%
  --   Novice : <= 4/6 = 66%
  --   Intermédiaire : <= 6/6 = 100%
  --   Expert : > 100% impossible -> on adapte :
  --   En pratique, le sondage ajoute 1-2 points. Sans sondage, on décale :
  --   correctAnswers / v_question_count :
  --     Debutant  : <= 33%
  --     Novice    : <= 66%
  --     Intermediaire : < 100%
  --     Expert    : 100% (tout juste)
  -- C'est ce que fait le code local pour 4 questions :
  --   0-1 juste -> Debutant, 2 -> Novice, 3 -> Intermediaire, 4 -> Expert
  -- Pour N questions, on garde les mêmes seuils en % :
  if v_pct <= 33 then
    v_level_code := 'debutant';
  elsif v_pct <= 66 then
    v_level_code := 'novice';
  elsif v_pct < 100 then
    v_level_code := 'intermediaire';
  else
    v_level_code := 'expert';
  end if;

  -- 9. Trouver le level_id par critère stable : learning_path_id + ordre
  --    On suppose que les niveaux ont un ordre : 1=debutant, 2=novice, 3=intermediaire, 4=expert
  --    On mappe le code vers l'ordre
  select id into v_level_id
  from public.levels
  where learning_path_id = v_quiz_row.learning_path_id
    and ordre = case v_level_code
      when 'debutant' then 1
      when 'novice' then 2
      when 'intermediaire' then 3
      when 'expert' then 4
    end
  limit 1;

  if v_level_id is null then
    raise exception 'Niveau introuvable pour learning_path % code %', v_quiz_row.learning_path_id, v_level_code;
  end if;

  -- 10. Insérer placement_attempts (result_level_id) + placement_answers
  insert into public.placement_attempts (quiz_id, user_id, result_level_id, completed_at)
  values (p_quiz_id, v_user_id, v_level_id, now())
  returning id into v_attempt_id;

  -- Insérer les réponses
  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    insert into public.placement_answers (attempt_id, question_id, option_id)
    values (
      v_attempt_id,
      (v_answer->>'question_id')::uuid,
      (v_answer->>'option_id')::uuid
    );
  end loop;

  -- 11. Le trigger trg_apply_placement_result met à jour users.current_level_id

  return v_level_id;
end;
$$;

-- Droits d'exécution
revoke execute on function public.submit_placement(uuid, jsonb) from public;
grant execute on function public.submit_placement(uuid, jsonb) to authenticated;