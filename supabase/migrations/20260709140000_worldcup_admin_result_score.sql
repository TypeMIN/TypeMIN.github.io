create or replace function public.worldcup_admin_set_result(
  p_admin_pin text,
  p_match_id text,
  p_team text,
  p_regular text,
  p_home int default null,
  p_away int default null,
  p_duration text default null
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
    result_home = p_home,
    result_away = p_away,
    result_duration = nullif(p_duration, ''),
    updated_at = now()
  where id = p_match_id;

  perform public.worldcup_touch();
  return public.worldcup_public_state();
end;
$$;

grant execute on function public.worldcup_admin_set_result(text, text, text, text, int, int, text) to anon;
