#!/usr/bin/env bash

set -euo pipefail

# Update the FitTwin iOS app Info.plist with API settings pulled from `.env`.
# You can optionally override values via CLI args or environment variables.
#
# Usage:
#   scripts/set_ios_api_endpoint.sh [api_url] [api_key] [env] [env_file]
# Defaults:
#   api_url  <- CLI arg 1 or $FITWIN_API_URL or $API_URL from .env or http://127.0.0.1:8000
#   api_key  <- CLI arg 2 or $FITWIN_API_KEY or $API_KEY from .env or staging-secret-key
#   env      <- CLI arg 3 or $FITWIN_ENV or $ENVIRONMENT from .env or dev
#   env_file <- CLI arg 4 or ${FITWIN_ENV_FILE:-.env}

CLI_URL="${1:-}"
CLI_KEY="${2:-}"
CLI_ENV="${3:-}"
ENV_FILE="${4:-${FITWIN_ENV_FILE:-.env}}"

if [[ -f "$ENV_FILE" ]]; then
  echo "[ios-api] Loading values from $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

API_URL="${CLI_URL:-${FITWIN_API_URL:-${API_URL:-http://127.0.0.1:8000}}}"
API_KEY="${CLI_KEY:-${FITWIN_API_KEY:-${API_KEY:-staging-secret-key}}}"
API_ENV="${CLI_ENV:-${FITWIN_ENV:-${ENVIRONMENT:-dev}}}"

if [[ -z "$API_URL" ]]; then
  echo "[ios-api] API URL could not be determined; pass it as the first argument or set FITWIN_API_URL." >&2
  exit 1
fi

PLIST="mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

if [[ ! -f "$PLIST" ]]; then
  echo "[ios-api] Info.plist not found at $PLIST" >&2
  exit 1
fi

if [[ ! -x "$PLIST_BUDDY" ]]; then
  echo "[ios-api] PlistBuddy not available at $PLIST_BUDDY" >&2
  exit 1
fi

set_key() {
  local key="$1"
  local value="$2"
  if "$PLIST_BUDDY" -c "Print :$key" "$PLIST" >/dev/null 2>&1; then
    "$PLIST_BUDDY" -c "Set :$key $value" "$PLIST"
  else
    "$PLIST_BUDDY" -c "Add :$key string $value" "$PLIST"
  fi
}

set_key "FITWIN_API_URL" "$API_URL"
set_key "FITWIN_API_KEY" "$API_KEY"
set_key "FITWIN_ENV" "$API_ENV"

echo "[ios-api] Updated Info.plist:"
echo "  FITWIN_API_URL = $API_URL"
echo "  FITWIN_API_KEY = $API_KEY"
echo "  FITWIN_ENV     = $API_ENV"
