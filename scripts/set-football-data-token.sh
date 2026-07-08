#!/usr/bin/env bash
set -euo pipefail

echo "football-data.org token setup"
echo "Create a token at https://www.football-data.org/client/register"
echo

read -r -p "football-data.org token: " FOOTBALL_DATA_TOKEN

if [[ -z "${FOOTBALL_DATA_TOKEN}" ]]; then
  echo "football-data.org token is required."
  exit 1
fi

npx supabase secrets set "FOOTBALL_DATA_TOKEN=${FOOTBALL_DATA_TOKEN}"
npx supabase functions deploy sync-football-data

echo
echo "Done. Open /worldcup and use the sync button, or wait for the automatic check."
