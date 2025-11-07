#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FULL_TEST_SCRIPT="$ROOT_DIR/scripts/full_local_test.sh"
POSTGRES_SETUP_SCRIPT="$ROOT_DIR/scripts/setup_postgres_test_db.sh"

if [[ ! -x "$FULL_TEST_SCRIPT" ]]; then
  echo "Cannot find full_local_test.sh at $FULL_TEST_SCRIPT" >&2
  exit 1
fi

# Load .env if available
if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT_DIR/.env"
  set +a
fi

echo "==================================================================="
echo " Pass 1: Mock / default configuration"
echo "==================================================================="
"$FULL_TEST_SCRIPT"

echo
echo "==================================================================="
echo " Pass 2: Local Postgres (DATABASE_MODE=LOCAL)"
echo "==================================================================="

export POSTGRES_PORT="${POSTGRES_PORT:-54322}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export LOCAL_DATABASE_URL="${LOCAL_DATABASE_URL:-postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$POSTGRES_DB}"

START_DOCKER="${START_DOCKER:-1}" \
  POSTGRES_PORT="$POSTGRES_PORT" \
  POSTGRES_USER="$POSTGRES_USER" \
  POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  POSTGRES_DB="$POSTGRES_DB" \
  "$POSTGRES_SETUP_SCRIPT"

DATABASE_MODE=LOCAL \
DATABASE_URL="$LOCAL_DATABASE_URL" \
"$FULL_TEST_SCRIPT"

echo
echo "==================================================================="
echo " Pass 3: Supabase (DATABASE_MODE=SUPA)"
echo "==================================================================="

if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  DATABASE_MODE=SUPA \
  SUPABASE_URL="$SUPABASE_URL" \
  SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  "$FULL_TEST_SCRIPT"
else
  echo "Skipping Supabase run: SUPABASE_URL and/or SUPABASE_SERVICE_ROLE_KEY not set."
  echo "Set them in .env or the environment to exercise the Supabase-backed tests."
fi
