#!/usr/bin/env zsh
  set -euo pipefail

  APP=${1:-}
  if [[ "$APP" != "shopper" && "$APP" != "brand" ]]; then
    echo "Usage: $0 <shopper|brand> [--skip-install]" >&2
    exit 1
  fi

  SKIP_INSTALL=false
  if [[ "${2:-}" == "--skip-install" ]]; then
    SKIP_INSTALL=true
  fi

  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
  APP_DIR="$REPO_ROOT/frontend/nativescript/${APP}-lab"
  NS="${NS_BIN:-ns}"

  log() { printf "\n\033[1;34m[FitTwin]\033[0m %s\n" "$1"; }
  err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2; }

  # --- Java ---
  JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
  if [[ -z "$JAVA_HOME" ]]; then
    log "Temurin 17 not found; installing via Homebrew"
    if ! command -v brew >/dev/null; then
      err "Homebrew is required; install it first."
      exit 1
    fi
    brew install --cask temurin@17 || brew install --cask temurin
    JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
  fi
  if [[ -z "$JAVA_HOME" ]]; then
    err "Java 17 still not detected; install a JDK and rerun."
    exit 1
  fi
  export JAVA_HOME
  export PATH="$JAVA_HOME/bin:$PATH"

  # --- ANDROID_HOME & SDK manager ---
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

  SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  if [[ ! -x "$SDKMANAGER" ]]; then
    log "Android cmdline tools missing; downloading…"
    tmp="$(mktemp -d)"
    curl -L https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip -o "$tmp/cmdline.zip"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    unzip -q "$tmp/cmdline.zip" -d "$tmp"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm -rf "$tmp"
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    chmod +x "$SDKMANAGER"
  fi

  log "Installing Android SDK components (platform-tools, android-34, build-tools 34.0.0)"
  "$SDKMANAGER" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
  yes | "$SDKMANAGER" --licenses >/dev/null

  # --- ADB device check ---
  if ! command -v adb >/dev/null; then
    err "adb not found even after installing platform-tools."
    exit 1
  fi
  adb_start="$(adb start-server 2>&1)"
  log "ADB devices:"
  adb devices -l

  # --- Reverse ports ---
  log "Reversing dev ports (3000, 3001, 3100)"
  adb reverse tcp:3000 tcp:3000 2>/dev/null || true
  [[ "$APP" == "shopper" ]] && adb reverse tcp:3001 tcp:3001 2>/dev/null || true
  [[ "$APP" == "brand"   ]] && adb reverse tcp:3100 tcp:3100 2>/dev/null || true

  # --- NativeScript clean/install/build ---
  cd "$APP_DIR"
  log "ns doctor android (sanity check)"
  $NS doctor android || log "ns doctor reported warnings; continuing"

  log "ns clean"
  $NS clean || err "ns clean failed; continuing"

  if [[ "$SKIP_INSTALL" == false ]]; then
    log "npm install"
    npm install --no-audit --no-fund
  else
    log "Skipping npm install (--skip-install)"
  fi

  log "Running ns run android --no-hmr"
  $NS run android --no-hmr