#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/supabase/migrations"

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  echo "Cannot find supabase migrations at $MIGRATIONS_DIR" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:15-alpine}"
POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-fittwin-postgres-test}"
POSTGRES_PORT="${POSTGRES_PORT:-54322}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-postgres}"
DATABASE_URL="${DATABASE_URL:-postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$POSTGRES_DB}"
START_DOCKER="${START_DOCKER:-1}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
start_container() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to start the local Postgres container. Set START_DOCKER=0 to skip container management." >&2
    exit 1
  fi

  if docker ps --format '{{.Names}}' | grep -qx "$POSTGRES_CONTAINER_NAME"; then
    echo "Postgres container '$POSTGRES_CONTAINER_NAME' already running."
    return
  fi

  if docker ps -a --format '{{.Names}}' | grep -qx "$POSTGRES_CONTAINER_NAME"; then
    echo "Removing old Postgres container '$POSTGRES_CONTAINER_NAME'..."
    docker rm -f "$POSTGRES_CONTAINER_NAME" >/dev/null
  fi

  echo "Starting Postgres container '$POSTGRES_CONTAINER_NAME' on port $POSTGRES_PORT..."
  docker run -d \
    --name "$POSTGRES_CONTAINER_NAME" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -p "$POSTGRES_PORT:5432" \
    "$POSTGRES_IMAGE" >/dev/null

  echo "Waiting for Postgres to accept connections..."
  until docker exec "$POSTGRES_CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; do
    sleep 1
  done
  echo "Postgres is ready."
}

require_psql() {
  if ! command -v psql >/dev/null 2>&1; then
    echo "psql is required. Install via 'brew install libpq && brew link --force libpq' or ensure it is in PATH." >&2
    exit 1
  fi
}

apply_sql() {
  local file="$1"
  echo "Applying $(basename "$file")"
  PGPASSWORD="$POSTGRES_PASSWORD" psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/dev/null
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
require_psql

if [[ "$START_DOCKER" == "1" ]]; then
  start_container
else
  echo "START_DOCKER=0 -> assuming Postgres is already running at $DATABASE_URL"
fi

echo "Creating schema using files under $MIGRATIONS_DIR"
apply_sql "$MIGRATIONS_DIR/init_schema.sql"
apply_sql "$MIGRATIONS_DIR/init_rls.sql"

while IFS= read -r migration; do
  apply_sql "$migration"
done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -name '0*.sql' | sort)

echo "Postgres test database is ready at $DATABASE_URL"
