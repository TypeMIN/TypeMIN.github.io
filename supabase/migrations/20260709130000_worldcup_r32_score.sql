alter table public.worldcup_matches drop constraint if exists worldcup_matches_stage_check;
alter table public.worldcup_matches add constraint worldcup_matches_stage_check
  check (stage in ('r32','r16','qf','sf','third','final'));

alter table public.worldcup_matches
  add column if not exists result_home int,
  add column if not exists result_away int,
  add column if not exists result_duration text;

insert into public.worldcup_matches(id, stage, label, team_a, team_b) values
  ('r32_1','r32','32강 1경기','팀 1','팀 2'),
  ('r32_2','r32','32강 2경기','팀 3','팀 4'),
  ('r32_3','r32','32강 3경기','팀 5','팀 6'),
  ('r32_4','r32','32강 4경기','팀 7','팀 8'),
  ('r32_5','r32','32강 5경기','팀 9','팀 10'),
  ('r32_6','r32','32강 6경기','팀 11','팀 12'),
  ('r32_7','r32','32강 7경기','팀 13','팀 14'),
  ('r32_8','r32','32강 8경기','팀 15','팀 16'),
  ('r32_9','r32','32강 9경기','팀 17','팀 18'),
  ('r32_10','r32','32강 10경기','팀 19','팀 20'),
  ('r32_11','r32','32강 11경기','팀 21','팀 22'),
  ('r32_12','r32','32강 12경기','팀 23','팀 24'),
  ('r32_13','r32','32강 13경기','팀 25','팀 26'),
  ('r32_14','r32','32강 14경기','팀 27','팀 28'),
  ('r32_15','r32','32강 15경기','팀 29','팀 30'),
  ('r32_16','r32','32강 16경기','팀 31','팀 32')
on conflict (id) do nothing;

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
    when 'r16' then 'r32'
    when 'qf' then 'r16'
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

create or replace function public.worldcup_public_state(
  p_participant_id uuid default null,
  p_pin text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  viewer_ok boolean := false;
begin
  if p_participant_id is not null and p_pin is not null then
    select exists (
      select 1
      from public.worldcup_participants
      where id = p_participant_id and pin = p_pin
    )
    into viewer_ok;
  end if;

  return jsonb_build_object(
    'participants', (
      select jsonb_agg(jsonb_build_object(
        'id', id,
        'slot', slot,
        'name', name,
        'registered', registered
      ) order by slot)
      from public.worldcup_participants
    ),
    'matches', (
      select jsonb_agg(jsonb_build_object(
        'id', id,
        'stage', stage,
        'label', label,
        'teamA', team_a,
        'teamB', team_b,
        'crestA', coalesce(team_a_crest, ''),
        'crestB', coalesce(team_b_crest, ''),
        'externalId', coalesce(external_id, ''),
        'kickoff', case when kickoff is null then '' else to_char(kickoff at time zone 'Asia/Seoul', 'YYYY-MM-DD"T"HH24:MI') end,
        'result', case
          when result_team is null then null
          else jsonb_build_object(
            'team', result_team,
            'regular', result_regular,
            'home', result_home,
            'away', result_away,
            'duration', result_duration
          )
        end
      ) order by case stage when 'qf' then 1 when 'sf' then 2 when 'third' then 3 else 4 end, id)
      from public.worldcup_matches
    ),
    'predictions', (
      select coalesce(jsonb_object_agg(participant_slot::text, match_map), '{}'::jsonb)
      from (
        select
          p.slot as participant_slot,
          jsonb_object_agg(
            pr.match_id,
            case
              when m.result_team is not null or (viewer_ok and pr.participant_id = p_participant_id) then
                jsonb_build_object('team', pr.team, 'regular', pr.regular, 'submitted', true)
              else
                jsonb_build_object('submitted', true, 'hidden', true)
            end
          ) as match_map
        from public.worldcup_predictions pr
        join public.worldcup_participants p on p.id = pr.participant_id
        join public.worldcup_matches m on m.id = pr.match_id
        group by p.slot
      ) masked
    ),
    'api', (
      select jsonb_build_object(
        'lastSync', case when api_last_sync is null then '' else to_char(api_last_sync at time zone 'Asia/Seoul', 'YYYY-MM-DD HH24:MI') end,
        'lastMessage', api_last_message
      )
      from public.worldcup_settings
      where id = true
    )
  );
end;
$$;
