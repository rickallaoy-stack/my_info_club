-- =========================================================
-- PLACEMENT : RPC get_placement_questions — LECTURE SÉCURISÉE
-- Retourne questions + options SANS est_correcte
-- À exécuter APRÈS schema.sql, add_section.sql, add_placement_section.sql
-- =========================================================

create or replace function public.get_placement_questions(
  p_quiz_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quiz_row record;
  v_user_section club_section;
  v_result jsonb;
begin
  -- 1. Utilisateur authentifié obligatoire
  if v_user_id is null then
    raise exception 'Non authentifié';
  end if;

  -- 2. Vérifier que le quiz existe
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

  -- 4. Construire le JSON : questions + options (sans est_correcte)
  select jsonb_agg(q_json order by q_json->>'ordre') into v_result
  from (
    select jsonb_build_object(
      'id', q.id,
      'enonce', q.enonce,
      'ordre', q.ordre,
      'options', (
        select jsonb_agg(o_json order by o_json->>'id')
        from (
          select jsonb_build_object(
            'id', o.id,
            'question_id', o.question_id,
            'texte', o.texte,
            'ordre', o.ordre
          ) as o_json
          from public.placement_options o
          where o.question_id = q.id
        ) opts
      )
    ) as q_json
    from public.placement_questions q
    where q.quiz_id = p_quiz_id
  ) questions;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;

-- Droits d'exécution
revoke execute on function public.get_placement_questions(uuid) from public;
grant execute on function public.get_placement_questions(uuid) to authenticated;