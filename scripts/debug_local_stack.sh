#!/usr/bin/env bash
set -euo pipefail

# Where to store logs for all steps
LOG_FILE="${1:-/tmp/fittwin.log}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== FitTwin Local Stack Debug ===" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"

cd "$ROOT_DIR"

run_step() {
  local title="$1"
  shift
  echo
  echo ">>> $title" | tee -a "$LOG_FILE"
  {
    echo "[command] $*"
    "$@"
  } 2>&1 | tee -a "$LOG_FILE"
  STACK_FAILED=
}

run_stack() {
  echo
  echo ">>> Running npm run dev:stack" | tee -a "$LOG_FILE"
  npm run dev:stack 2>&1 | tee -a "$LOG_FILE" || true
}

# Step 1: reset docker container
run_step "Removing existing Postgres container" docker rm -f fittwin-postgres-test 2>/dev/null || true

# Step 2: run setup_postgres_test_db.sh
run_step "Running scripts/setup_postgres_test_db.sh" "$ROOT_DIR/scripts/setup_postgres_test_db.sh"

echo
echo
echo "Next steps:"
echo "  export DATABASE_MODE=local (and NS_TEST_STATUS_URL)."
echo "  npm run dev:stack 2>&1 | tee -a $LOG_FILE"
echo "Then say 'go' and I'll tail the log: tail -n 120 $LOG_FILE"
