-- World Cup betting app schema for Supabase.
-- Run this once in Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.worldcup_settings (
  id boolean primary key default true,
  admin_pin text not null default '0000',
  api_last_sync timestamptz,
  api_last_message text not null default '',
  updated_at timestamptz not null default now(),
  constraint worldcup_settings_singleton check (id)
);

alter table public.worldcup_settings
  add column if not exists api_last_sync timestamptz,
  add column if not exists api_last_message text not null default '';

create table if not exists public.worldcup_participants (
  id uuid primary key default gen_random_uuid(),
  slot int not null unique check (slot between 1 and 5),
  name text not null,
  pin text not null,
  registered boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.worldcup_participants
  add column if not exists registered boolean not null default false;

create table if not exists public.worldcup_matches (
  id text primary key,
  stage text not null check (stage in ('qf', 'sf', 'third', 'final')),
  label text not null,
  team_a text not null,
  team_b text not null,
  kickoff timestamptz,
  result_team text check (result_team in ('A', 'B')),
  result_regular text check (result_regular in ('win', 'draw')),
  external_id text,
  updated_at timestamptz not null default now()
);

create table if not exists public.worldcup_predictions (
  participant_id uuid not null references public.worldcup_participants(id) on delete cascade,
  match_id text not null references public.worldcup_matches(id) on delete cascade,
  team text not null check (team in ('A', 'B')),
  regular text not null check (regular in ('win', 'draw')),
  updated_at timestamptz not null default now(),
  primary key (participant_id, match_id)
);

create table if not exists public.worldcup_events (
  id bigint generated always as identity primary key,
  topic text not null default 'worldcup',
  created_at timestamptz not null default now()
);

do $$
begin
  alter publication supabase_realtime add table public.worldcup_events;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

alter table public.worldcup_settings enable row level security;
alter table public.worldcup_participants enable row level security;
alter table public.worldcup_matches enable row level security;
alter table public.worldcup_predictions enable row level security;
alter table public.worldcup_events enable row level security;

drop policy if exists "public can read events" on public.worldcup_events;
create policy "public can read events"
  on public.worldcup_events for select
  to anon
  using (true);

create or replace function public.worldcup_touch()
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.worldcup_events(topic) values ('worldcup');
$$;

create or replace function public.worldcup_seed()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.worldcup_settings(id, admin_pin)
  values (true, '0000')
  on conflict (id) do nothing;

  insert into public.worldcup_participants(slot, name, pin)
  values
    (1, '빈 자리 1', ''),
    (2, '빈 자리 2', ''),
    (3, '빈 자리 3', ''),
    (4, '빈 자리 4', ''),
    (5, '빈 자리 5', '')
  on conflict (slot) do nothing;

  insert into public.worldcup_matches(id, stage, label, team_a, team_b)
  values
    ('qf1', 'qf', '8강 1경기', '프랑스', '상대팀'),
    ('qf2', 'qf', '8강 2경기', '팀 A', '팀 B'),
    ('qf3', 'qf', '8강 3경기', '팀 C', '팀 D'),
    ('qf4', 'qf', '8강 4경기', '팀 E', '팀 F'),
    ('sf1', 'sf', '4강 1경기', '팀 G', '팀 H'),
    ('sf2', 'sf', '4강 2경기', '팀 I', '팀 J'),
    ('third', 'third', '3·4위전', '팀 K', '팀 L'),
    ('final', 'final', '결승', '팀 M', '팀 N')
  on conflict (id) do nothing;

  perform public.worldcup_touch();
end;
$$;

create or replace function public.worldcup_join(p_name text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_name text := trim(p_name);
  participant_row public.worldcup_participants%rowtype;
begin
  if clean_name is null or length(clean_name) < 1 then
    raise exception 'name is required';
  end if;

  if p_pin !~ '^[0-9]{4}$' then
    raise exception 'pin must be 4 digits';
  end if;

  if clean_name = '관리자' then
    if public.worldcup_is_admin(p_pin) then
      return jsonb_build_object('role', 'admin');
    end if;
    return jsonb_build_object('role', null, 'reason', 'pin_mismatch');
  end if;

  select *
  into participant_row
  from public.worldcup_participants
  where registered = true and name = clean_name
  limit 1;

  if participant_row.id is not null then
    if participant_row.pin <> p_pin then
      return jsonb_build_object('role', null, 'reason', 'pin_mismatch');
    end if;

    return jsonb_build_object(
      'role', 'participant',
      'participantId', participant_row.id,
      'slot', participant_row.slot,
      'name', participant_row.name
    );
  end if;

  select *
  into participant_row
  from public.worldcup_participants
  where registered = false
  order by slot
  limit 1
  for update;

  if participant_row.id is null then
    return jsonb_build_object('role', null, 'reason', 'full');
  end if;

  update public.worldcup_participants
  set name = clean_name,
      pin = p_pin,
      registered = true,
      updated_at = now()
  where id = participant_row.id
  returning * into participant_row;

  perform public.worldcup_touch();

  return jsonb_build_object(
    'role', 'participant',
    'participantId', participant_row.id,
    'slot', participant_row.slot,
    'name', participant_row.name
  );
end;
$$;

create or replace function public.worldcup_is_admin(p_pin text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.worldcup_settings
    where id = true and admin_pin = p_pin
  );
$$;

create or replace function public.worldcup_login(p_user text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  participant_row public.worldcup_participants%rowtype;
begin
  if p_user = 'admin' and public.worldcup_is_admin(p_pin) then
    return jsonb_build_object('role', 'admin');
  end if;

  select *
  into participant_row
  from public.worldcup_participants
  where id::text = p_user and pin = p_pin;

  if participant_row.id is null then
    return jsonb_build_object('role', null);
  end if;

  return jsonb_build_object(
    'role', 'participant',
    'participantId', participant_row.id,
    'slot', participant_row.slot,
    'name', participant_row.name
  );
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

  if match_row.result_team is not null or (match_row.kickoff is not null and now() >= match_row.kickoff) then
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

create or replace function public.worldcup_admin_state(p_admin_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  base_state jsonb;
begin
  if not public.worldcup_is_admin(p_admin_pin) then
    raise exception 'invalid admin pin';
  end if;

  base_state := public.worldcup_public_state();
  return base_state
    || jsonb_build_object(
      'participants', (
        select jsonb_agg(jsonb_build_object(
          'id', id,
          'slot', slot,
          'name', name,
          'registered', registered
        ) order by slot)
        from public.worldcup_participants
      )
    );
end;
$$;

create or replace function public.worldcup_admin_save_setup(
  p_admin_pin text,
  p_admin_pin_next text,
  p_participants jsonb,
  p_matches jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  participant_item jsonb;
  match_item jsonb;
begin
  if not public.worldcup_is_admin(p_admin_pin) then
    raise exception 'invalid admin pin';
  end if;

  if p_admin_pin_next is not null and length(p_admin_pin_next) > 0 then
    update public.worldcup_settings
    set admin_pin = p_admin_pin_next, updated_at = now()
    where id = true;
  end if;

  for participant_item in select * from jsonb_array_elements(p_participants)
  loop
    update public.worldcup_participants
    set
      name = case
        when coalesce((participant_item->>'registered')::boolean, registered) then participant_item->>'name'
        else '빈 자리 ' || (participant_item->>'slot')
      end,
      pin = case
        when coalesce((participant_item->>'registered')::boolean, registered) then pin
        else ''
      end,
      registered = coalesce((participant_item->>'registered')::boolean, registered),
      updated_at = now()
    where slot = (participant_item->>'slot')::int;
  end loop;

  delete from public.worldcup_predictions pr
  using public.worldcup_participants p
  where pr.participant_id = p.id and p.registered = false;

  for match_item in select * from jsonb_array_elements(p_matches)
  loop
    update public.worldcup_matches
    set
      team_a = match_item->>'teamA',
      team_b = match_item->>'teamB',
      external_id = nullif(match_item->>'externalId', ''),
      kickoff = case
        when nullif(match_item->>'kickoff', '') is null then null
        else (match_item->>'kickoff')::timestamp at time zone 'Asia/Seoul'
      end,
      updated_at = now()
    where id = match_item->>'id';
  end loop;

  perform public.worldcup_touch();
  return public.worldcup_public_state();
end;
$$;

create or replace function public.worldcup_admin_set_result(
  p_admin_pin text,
  p_match_id text,
  p_team text,
  p_regular text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.worldcup_is_admin(p_admin_pin) then
    raise exception 'invalid admin pin';
  end if;

  update public.worldcup_matches
  set
    result_team = nullif(p_team, ''),
    result_regular = nullif(p_regular, ''),
    updated_at = now()
  where id = p_match_id;

  perform public.worldcup_touch();
  return public.worldcup_public_state();
end;
$$;

grant usage on schema public to anon;
grant execute on function public.worldcup_seed() to anon;
grant execute on function public.worldcup_join(text, text) to anon;
grant execute on function public.worldcup_login(text, text) to anon;
grant execute on function public.worldcup_public_state(uuid, text) to anon;
grant execute on function public.worldcup_save_prediction(uuid, text, text, text, text) to anon;
grant execute on function public.worldcup_admin_state(text) to anon;
grant execute on function public.worldcup_admin_save_setup(text, text, jsonb, jsonb) to anon;
grant execute on function public.worldcup_admin_set_result(text, text, text, text) to anon;
grant select on public.worldcup_events to anon;

select public.worldcup_seed();
