alter table public.worldcup_matches
  add column if not exists team_a_crest text,
  add column if not exists team_b_crest text,
  add column if not exists synced_pre boolean not null default false;

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
          else jsonb_build_object('team', result_team, 'regular', result_regular)
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
