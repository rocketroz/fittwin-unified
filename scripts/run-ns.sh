#!/usr/bin/env zsh
set -euo pipefail

if (( $# < 2 )); then
  echo "Usage: $0 <shopper|brand> <ios|android> [extra ns args]" >&2
  exit 1
fi

APP="$1"
shift
PLATFORM="$1"
shift

case "$APP" in
  shopper) APP_DIR="frontend/nativescript/shopper-lab" ;;
  brand) APP_DIR="frontend/nativescript/brand-lab" ;;
  *)
    echo "Unknown app: $APP (expected shopper or brand)" >&2
    exit 1
    ;;
 esac

if [[ ! -d "$APP_DIR" ]]; then
  echo "App directory not found: $APP_DIR" >&2
  exit 1
fi

cd "$APP_DIR"

export NS_CLI_HOME="$(pwd)/.nscli"
mkdir -p "$NS_CLI_HOME"

CMD=(ns run "$PLATFORM" --no-hmr --env.skipInstall)
if (( $# > 0 )); then
  CMD+=($@)
fi

echo "Running: ${CMD[*]} in $APP_DIR"
exec "${CMD[@]}"
