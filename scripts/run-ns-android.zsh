#!/usr/bin/env zsh
set -euo pipefail

if (( $# < 1 )); then
  echo "Usage: $0 <shopper|brand> [--skip-install] [<additional NativeScript args>]" >&2
  exit 1
fi

APP=$1
if [[ "$APP" != "shopper" && "$APP" != "brand" ]]; then
  echo "Usage: $0 <shopper|brand> [--skip-install] [<additional NativeScript args>]" >&2
  exit 1
fi
shift

SKIP_INSTALL=false
EXTRA_ARGS=()
NS_LOG_LEVEL=${NS_LOG_LEVEL:-info}
USER_SPECIFIED_LOG=false

while (( $# )); do
  case "$1" in
    --skip-install)
      SKIP_INSTALL=true
      ;;
    --log)
      if [[ -n "${2:-}" ]]; then
        NS_LOG_LEVEL=$2
        USER_SPECIFIED_LOG=true
        EXTRA_ARGS+=("$1" "$2")
        shift
      else
        EXTRA_ARGS+=("$1")
      fi
      ;;
    --log=*)
      NS_LOG_LEVEL=${1#--log=}
      USER_SPECIFIED_LOG=true
      EXTRA_ARGS+=("$1")
      ;;
    --log-level)
      if [[ -n "${2:-}" ]]; then
        NS_LOG_LEVEL=$2
        USER_SPECIFIED_LOG=true
        EXTRA_ARGS+=("$1" "$2")
        shift
      else
        EXTRA_ARGS+=("$1")
      fi
      ;;
    --log-level=*)
      NS_LOG_LEVEL=${1#--log-level=}
      USER_SPECIFIED_LOG=true
      EXTRA_ARGS+=("$1")
      ;;
    *)
      EXTRA_ARGS+=("$1")
      ;;
  esac
  shift
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
APP_DIR="$REPO_ROOT/frontend/nativescript/${APP}-lab"
NS_CMD="${NS_BIN:-ns}"
CMDLINE_TOOLS_VERSION=${CMDLINE_TOOLS_VERSION:-11579550}
CMDLINE_TOOLS_ZIP="commandlinetools-mac-${CMDLINE_TOOLS_VERSION}_latest.zip"

log() { printf "\n\033[1;34m[FitTwin]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2; exit 1; }

run_ns_doctor() {
  log "ns doctor android --log $NS_LOG_LEVEL (press ESC to skip)"
  log "  ANDROID_HOME=$ANDROID_HOME"
  log "  NS log level=$NS_LOG_LEVEL"
  if command -v node >/dev/null 2>&1; then
    log "  node $(node -v)"
  else
    warn "node binary not found"
  fi
  if command -v npm >/dev/null 2>&1; then
    log "  npm $(npm -v)"
  fi
  if command -v $NS_CMD >/dev/null 2>&1; then
    log "  ns $($NS_CMD --version 2>/dev/null | head -n 1)"
  fi
  if command -v java >/dev/null 2>&1; then
    log "  java $(java -version 2>&1 | head -n 1)"
  fi
  if command -v adb >/dev/null 2>&1; then
    log "  adb $(adb version 2>/dev/null | head -n 1)"
  fi
  if [[ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
    log "  sdkmanager version $($ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --version 2>/dev/null | tr -d '\r')"
  fi
  if [[ ! -t 0 ]]; then
    CI=1 NS_TRACE_LEVEL=$NS_LOG_LEVEL $NS_CMD doctor android --log "$NS_LOG_LEVEL" || warn "ns doctor reported warnings"
    return
  fi

  set +e
  CI=1 NS_TRACE_LEVEL=$NS_LOG_LEVEL $NS_CMD doctor android --log "$NS_LOG_LEVEL" &
  doc_pid=$!
  skipped=false

  while kill -0 $doc_pid 2>/dev/null; do
    if read -rs -t 0.1 -k 1 key 2>/dev/null; then
      if [[ $key == $'\e' ]]; then
        log "Skipping ns doctor (ESC pressed)"
        skipped=true
        kill -INT $doc_pid 2>/dev/null
        for _ in {1..20}; do
          sleep 0.1
          if ! kill -0 $doc_pid 2>/dev/null; then
            break
          fi
        done
        if kill -0 $doc_pid 2>/dev/null; then
          kill -TERM $doc_pid 2>/dev/null
        fi
        for _ in {1..20}; do
          sleep 0.1
          if ! kill -0 $doc_pid 2>/dev/null; then
            break
          fi
        done
        if kill -0 $doc_pid 2>/dev/null; then
          kill -KILL $doc_pid 2>/dev/null
        fi
        break
      fi
    fi
  done

  wait $doc_pid 2>/dev/null
  if [[ $skipped == false ]]; then
    doctor_status=$?
    if (( doctor_status != 0 )); then
      warn "ns doctor reported warnings"
    fi
  fi

  set -e
}

# --- Java ---
if [[ -z "${JAVA_HOME:-}" ]]; then
  if JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null); then
    :
  else
    for candidate in \
      /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
      /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home \
      /Library/Java/JavaVirtualMachines/corretto-17.jdk/Contents/Home; do
      if [[ -d "$candidate" ]]; then
        JAVA_HOME="$candidate"
        break
      fi
    done
  fi
fi
if [[ -z "${JAVA_HOME:-}" ]]; then
  log "Installing Temurin JDK (17) via Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    fail "Homebrew not found. Install Homebrew first."
  fi
  if ! brew install --cask temurin@17 >/dev/null 2>&1; then
    warn "temurin@17 cask unavailable; installing latest Temurin"
    brew install --cask temurin || fail "Failed to install Temurin JDK"
  fi
  JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
fi
[[ -z "${JAVA_HOME:-}" ]] && fail "Java 17 not detected even after install."
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

# --- Android SDK ---
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$SDKMANAGER" ]]; then
  log "Android cmdline tools not found; bootstrapping..."
  tmp="$(mktemp -d)"
  local_zip="$REPO_ROOT/$CMDLINE_TOOLS_ZIP"
  source_zip="$tmp/$CMDLINE_TOOLS_ZIP"
  if [[ -f "$local_zip" ]]; then
    log "Using local $CMDLINE_TOOLS_ZIP"
    cp "$local_zip" "$source_zip"
  else
    url="https://dl.google.com/android/repository/$CMDLINE_TOOLS_ZIP"
    log "Downloading $CMDLINE_TOOLS_ZIP"
    curl -L "$url" -o "$source_zip" || fail "Failed to download Android cmdline tools"
  fi
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -q "$source_zip" -d "$tmp" || fail "Failed to unzip Android cmdline tools"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" || fail "Failed to install Android cmdline tools"
  rm -rf "$tmp"
  SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  chmod +x "$SDKMANAGER"
fi

missing_components=()
if [[ ! -d "$ANDROID_HOME/platform-tools" ]]; then
  missing_components+=("platform-tools")
fi
if [[ ! -d "$ANDROID_HOME/platforms/android-34" ]]; then
  missing_components+=("platforms;android-34")
fi
if [[ ! -d "$ANDROID_HOME/build-tools/34.0.0" ]]; then
  missing_components+=("build-tools;34.0.0")
fi

if (( ${#missing_components[@]} > 0 )); then
  log "Installing Android SDK components (${missing_components[*]})"
  "$SDKMANAGER" "${missing_components[@]}"
else
  log "Required Android SDK components already present; skipping install"
fi

if [[ -f "$ANDROID_HOME/licenses/android-sdk-license" ]]; then
  log "SDK licenses already accepted"
else
  log "Accepting Android SDK licenses"
  yes | "$SDKMANAGER" --licenses >/dev/null
fi

# --- ADB device check ---
if ! command -v adb >/dev/null 2>&1; then
  fail "adb not found even after installing platform-tools."
fi
adb start-server >/dev/null 2>&1

log "ADB devices:"
adb devices -l

# --- Reverse ports ---
log "Reversing dev ports (3000, 3001, 3100)"
adb reverse tcp:3000 tcp:3000 2>/dev/null || true
[[ "$APP" == "shopper" ]] && adb reverse tcp:3001 tcp:3001 2>/dev/null || true
[[ "$APP" == "brand"   ]] && adb reverse tcp:3100 tcp:3100 2>/dev/null || true

# --- NativeScript build ---
cd "$APP_DIR"

run_ns_doctor

log "ns clean"
$NS_CMD clean || warn "ns clean reported an issue"

if [[ "$SKIP_INSTALL" == false ]]; then
  log "npm install"
  npm install --no-audit --no-fund
else
  log "Skipping npm install ( --skip-install )"
fi

RUN_LOG="$APP_DIR/.ns-run-android.log"
log "ns run android --no-hmr (logs -> $RUN_LOG; press Ctrl+C to stop)"
>"$RUN_LOG"
start_time=$(date +%s)
set +e
log "NativeScript CLI log level: $NS_LOG_LEVEL"
RUN_ARGS=(run android --no-hmr)
if [[ $USER_SPECIFIED_LOG == false ]]; then
  RUN_ARGS+=(--log "$NS_LOG_LEVEL")
fi
if (( ${#EXTRA_ARGS[@]} > 0 )); then
  RUN_ARGS+=("${EXTRA_ARGS[@]}")
  log "Forwarding extra ns args: ${EXTRA_ARGS[*]}"
fi
{
  CI=1 NS_TRACE_LEVEL=$NS_LOG_LEVEL $NS_CMD "${RUN_ARGS[@]}" 2>&1 &
  run_pid=$!
  trap "kill $run_pid 2>/dev/null" INT TERM
  wait $run_pid
  cmd_status=$?
} | tee "$RUN_LOG"
tee_status=${pipestatus[1]:-0}

set -e
if (( tee_status != 0 )); then
  warn "tee exited with status $tee_status"
fi
if (( cmd_status != 0 )); then
  warn "ns run android exited with status $cmd_status (see $RUN_LOG)"
else
  duration=$(( $(date +%s) - start_time ))
  log "ns run android finished in ${duration}s"
fi
