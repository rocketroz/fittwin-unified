#!/usr/bin/env zsh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
APP_DIR="$REPO_ROOT/tools/lab-monitor"

log() { printf "\n\033[1;34m[FitTwin]\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2; exit 1; }

if ! command -v cargo >/dev/null 2>&1; then
  fail "Rust toolchain not found. Install Rust via https://rustup.rs and rerun."
fi

log "Building lab-monitor (release)"
cd "$APP_DIR"
cargo run --release -- "$@"
