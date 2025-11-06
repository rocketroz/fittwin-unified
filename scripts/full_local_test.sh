#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Load .env if present (mirrors what direnv does)
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  . "$REPO_ROOT/.env"
  set +a
fi

export API_KEY="${API_KEY:-staging-secret-key}"
export FITWIN_API_URL="${FITWIN_API_URL:-http://127.0.0.1:8000/api}"
export NS_MEASUREMENTS_API_URL="${NS_MEASUREMENTS_API_URL:-$FITWIN_API_URL}"
export NS_MEASUREMENTS_API_KEY="${NS_MEASUREMENTS_API_KEY:-$API_KEY}"
export NS_LAB_URL="${NS_LAB_URL:-http://localhost:3001/ar-lab}"
export NS_BRAND_URL="${NS_BRAND_URL:-http://localhost:3100}"

     echo "==> Running npm test"
     npm run test

     echo "==> Running npm test:full"
     npm run test:full || true
