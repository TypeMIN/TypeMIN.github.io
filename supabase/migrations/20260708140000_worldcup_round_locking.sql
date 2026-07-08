create or replace function public.worldcup_save_prediction(
  p_participant_id uuid,
  p_pin text,
  p_match_id text,
  p_team text,
  p_regular text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  match_row public.worldcup_matches%rowtype;
  feeder_stage text;
  feeder_finished boolean;
  stage_has_result boolean;
  stage_first_kickoff timestamptz;
begin
  if not exists (
    select 1 from public.worldcup_participants
    where id = p_participant_id and pin = p_pin
  ) then
    raise exception 'invalid participant credentials';
  end if;

  select *
  into match_row
  from public.worldcup_matches
  where id = p_match_id;

  if match_row.id is null then
    raise exception 'match not found';
  end if;

  feeder_stage := case match_row.stage
    when 'sf' then 'qf'
    when 'third' then 'sf'
    when 'final' then 'third'
    else null
  end;

  if feeder_stage is not null then
    select coalesce(bool_and(result_team is not null), false)
    into feeder_finished
    from public.worldcup_matches
    where stage = feeder_stage;

    if not feeder_finished then
      raise exception 'round not open';
    end if;
  end if;

  select coalesce(bool_or(result_team is not null), false), min(kickoff)
  into stage_has_result, stage_first_kickoff
  from public.worldcup_matches
  where stage = match_row.stage;

  if stage_has_result or (stage_first_kickoff is not null and stage_first_kickoff <= now()) then
    raise exception 'prediction is locked';
  end if;

  if p_team is null or p_regular is null then
    delete from public.worldcup_predictions
    where participant_id = p_participant_id and match_id = p_match_id;
  else
    insert into public.worldcup_predictions(participant_id, match_id, team, regular, updated_at)
    values (p_participant_id, p_match_id, p_team, p_regular, now())
    on conflict (participant_id, match_id)
    do update set team = excluded.team, regular = excluded.regular, updated_at = now();
  end if;

  perform public.worldcup_touch();
  return public.worldcup_public_state(p_participant_id, p_pin);
end;
$$;
