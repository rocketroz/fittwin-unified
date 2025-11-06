#!/bin/zsh
# Helper script to run the full local stack + NativeScript capture QA prerequisites.

set -euo pipefail

REPO_ROOT="${0:a:h:h}"
cd "$REPO_ROOT"

export API_KEY="${API_KEY:-staging-secret-key}"
export FITWIN_API_URL="${FITWIN_API_URL:-http://127.0.0.1:8000/api}"
export NS_MEASUREMENTS_API_URL="${NS_MEASUREMENTS_API_URL:-$FITWIN_API_URL}"
export NS_MEASUREMENTS_API_KEY="${NS_MEASUREMENTS_API_KEY:-$API_KEY}"
export NS_LAB_URL="${NS_LAB_URL:-http://localhost:3001/ar-lab}"
export NS_BRAND_URL="${NS_BRAND_URL:-http://localhost:3100}"

echo "==> Environment"
echo "API_KEY=$API_KEY"
echo "FITWIN_API_URL=$FITWIN_API_URL"
echo "NS_LAB_URL=$NS_LAB_URL"
echo "NS_BRAND_URL=$NS_BRAND_URL"

echo "==> Running npm test"
npm run test

echo "==> Running npm test:full"
npm run test:full || true
