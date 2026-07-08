#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="qchzcrtjksusgrdevxkb"

echo "Supabase World Cup setup"
echo
echo "You need:"
echo "1. A Supabase access token from https://supabase.com/dashboard/account/tokens"
echo "2. The database password for project ${PROJECT_REF}"
echo "3. Optional: a football-data.org API token from https://www.football-data.org/client/register"
echo

read -r -p "Supabase access token: " SUPABASE_ACCESS_TOKEN
read -r -s -p "Database password: " SUPABASE_DB_PASSWORD
echo
read -r -p "football-data.org token (press Enter to skip): " FOOTBALL_DATA_TOKEN
echo

if [[ -z "${SUPABASE_ACCESS_TOKEN}" || -z "${SUPABASE_DB_PASSWORD}" ]]; then
  echo "Token and database password are required."
  exit 1
fi

npx supabase login --token "${SUPABASE_ACCESS_TOKEN}"
npx supabase link --project-ref "${PROJECT_REF}" --password "${SUPABASE_DB_PASSWORD}"
npx supabase db push --yes

if [[ -n "${FOOTBALL_DATA_TOKEN}" ]]; then
  npx supabase secrets set "FOOTBALL_DATA_TOKEN=${FOOTBALL_DATA_TOKEN}"
fi

npx supabase functions deploy sync-football-data

echo
echo "Done. Restart the Astro dev server and open /worldcup."
