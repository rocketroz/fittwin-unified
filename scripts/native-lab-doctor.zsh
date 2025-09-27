#!/usr/bin/env zsh
# FitTwin Native Lab Doctor
# Comprehensive environment doctor/fixer for NativeScript iOS & Android tooling.

set -uo pipefail

autoload -U colors >/dev/null 2>&1 && colors
if [[ -z ${fg[green]-} ]]; then
  typeset -A fg
  fg[green]=''
  fg[yellow]=''
  fg[red]=''
  fg[blue]=''
  fg[magenta]=''
  fg[cyan]=''
  fg[white]=''
  reset_color=''
fi

info()    { printf "%s[INFO]%s %s\n"    "${fg[cyan]}"   "${reset_color}" "$1"; }
success() { printf "%s[OK]%s   %s\n"    "${fg[green]}"  "${reset_color}" "$1"; }
warn()    { printf "%s[WARN]%s %s\n"   "${fg[yellow]}" "${reset_color}" "$1"; }
section() { printf "\n%s=== %s ===%s\n" "${fg[magenta]}" "$1" "${reset_color}"; }

typeset -A STATE DETAILS
record_state() {
  STATE[$1]="$2"
  DETAILS[$1]="$3"
}

summary_row() {
  local key="$1" row_state row_detail
  row_state=${STATE[$key]:-"${fg[red]}✖${reset_color}"}
  row_detail=${DETAILS[$key]:-"--"}
  printf " %-20s %-6s %s\n" "$key" "$row_state" "$row_detail"
}

ORIGINAL_PATH="$PATH"
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LICENSE_LOG="/tmp/native-lab-licenses.log"
SDKUPDATE_LOG="/tmp/native-lab-sdkupdate.log"

section "System Prereqs"
if command -v curl >/dev/null 2>&1; then
  record_state "curl" "${fg[green]}✔${reset_color}" "$(curl --version 2>/dev/null | head -n1)"
else
  record_state "curl" "${fg[red]}✖${reset_color}" "missing"
  warn "curl is required to download Android command-line tools."
fi

if command -v unzip >/dev/null 2>&1; then
  record_state "unzip" "${fg[green]}✔${reset_color}" "$(unzip -v 2>/dev/null | head -n1)"
else
  record_state "unzip" "${fg[red]}✖${reset_color}" "missing"
  warn "unzip is required to extract Android command-line tools."
fi

if command -v brew >/dev/null 2>&1; then
  record_state "brew" "${fg[green]}✔${reset_color}" "$(brew --version | head -n1)"
else
  record_state "brew" "${fg[yellow]}⚠${reset_color}" "missing"
  warn "Homebrew not detected; automatic JDK installation may be skipped."
fi

section "Node.js & NativeScript CLI"
if command -v node >/dev/null 2>&1; then
  record_state "node" "${fg[green]}✔${reset_color}" "$(node -v)"
else
  record_state "node" "${fg[red]}✖${reset_color}" "missing"
  warn "Install Node.js (nvm recommended) before running the labs."
fi

if command -v npm >/dev/null 2>&1; then
  record_state "npm" "${fg[green]}✔${reset_color}" "$(npm -v)"
else
  record_state "npm" "${fg[red]}✖${reset_color}" "missing"
fi

if command -v ns >/dev/null 2>&1; then
  record_state "ns" "${fg[green]}✔${reset_color}" "$(ns --version 2>/dev/null)"
else
  if command -v npm >/dev/null 2>&1 && npm install -g nativescript >/dev/null 2>&1; then
    record_state "ns" "${fg[green]}✔${reset_color}" "$(ns --version 2>/dev/null)"
  else
    record_state "ns" "${fg[yellow]}⚠${reset_color}" "install failed"
    warn "NativeScript CLI install failed; run 'npm install -g nativescript' manually."
  fi
fi

section "Java Toolchain"
typeset -a JAVA_CANDIDATES
JAVA_CANDIDATES=(24 21 17)
JAVA_SELECTED=""
for version in ${JAVA_CANDIDATES[@]}; do
  home=$(/usr/libexec/java_home -v $version 2>/dev/null || true)
  if [[ -n "$home" ]]; then
    JAVA_SELECTED="$home"
    break
  fi
done

if [[ -z "$JAVA_SELECTED" ]] && command -v brew >/dev/null 2>&1; then
  warn "Java 17+ not found. Attempting Temurin install via Homebrew."
  if brew info --cask temurin@17 >/dev/null 2>&1; then
    brew install --cask temurin@17 >/dev/null 2>&1 || warn "temurin@17 install failed"
  else
    brew install --cask temurin >/dev/null 2>&1 || warn "temurin install failed"
  fi
  JAVA_SELECTED=$(/usr/libexec/java_home -v 24 2>/dev/null || /usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home -v 17 2>/dev/null || true)
fi

if [[ -n "$JAVA_SELECTED" ]]; then
  export JAVA_HOME="$JAVA_SELECTED"
  PATH="$JAVA_HOME/bin:$ORIGINAL_PATH"
  JAVA_VERSION=$(java -version 2>&1 | head -n1)
  record_state "java" "${fg[green]}✔${reset_color}" "$JAVA_VERSION"
else
  record_state "java" "${fg[red]}✖${reset_color}" "missing ≥17"
  warn "Install Temurin JDK (17+)."
fi

section "Android SDK"
ANDROID_HOME_DEFAULT="$HOME/Library/Android/sdk"
if [[ -z ${ANDROID_HOME:-} ]]; then
  export ANDROID_HOME="$ANDROID_HOME_DEFAULT"
else
  export ANDROID_HOME="$ANDROID_HOME"
fi
mkdir -p "$ANDROID_HOME"
record_state "ANDROID_HOME" "${fg[green]}✔${reset_color}" "$ANDROID_HOME"

resolve_sdkmanager() {
  typeset -a candidates
  candidates=("$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "$ANDROID_HOME/cmdline-tools/bin/sdkmanager")
  if [[ -d "$ANDROID_HOME/cmdline-tools" ]]; then
    setopt local_options null_glob
    for p in "$ANDROID_HOME"/cmdline-tools/*/bin/sdkmanager; do
      candidates+=("$p")
    done
  fi
  if command -v sdkmanager >/dev/null 2>&1; then
    candidates+=("$(command -v sdkmanager)")
  fi
  for p in ${(u)candidates[@]}; do
    if [[ -x "$p" ]]; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

SDKMANAGER_PATH="$(resolve_sdkmanager 2>/dev/null || true)"

download_cmdline_tools() {
  local url="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
  local tmpdir
  tmpdir=$(mktemp -d)
  info "Downloading Android command-line tools"
  if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    warn "curl and unzip are required to download command-line tools."
    rm -rf "$tmpdir"
    return 1
  fi
  if ! curl -L "$url" -o "$tmpdir/cli.zip" >/dev/null 2>&1; then
    rm -rf "$tmpdir"
    return 1
  fi
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -oq "$tmpdir/cli.zip" -d "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmpdir/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"
  chmod +x "$ANDROID_HOME/cmdline-tools/latest/bin"/* 2>/dev/null || true
  SDKMANAGER_PATH="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  return 0
}

if [[ -z "$SDKMANAGER_PATH" ]]; then
  if download_cmdline_tools; then
    success "Android command-line tools installed"
  else
    warn "Unable to install Android command-line tools automatically"
  fi
  SDKMANAGER_PATH="$(resolve_sdkmanager 2>/dev/null || true)"
fi

if [[ -n "$SDKMANAGER_PATH" ]]; then
  record_state "sdkmanager" "${fg[green]}✔${reset_color}" "$SDKMANAGER_PATH"
  PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$(dirname "$SDKMANAGER_PATH"):$PATH"
else
  record_state "sdkmanager" "${fg[red]}✖${reset_color}" "missing"
fi

android_licenses_present() {
  [[ -d "$ANDROID_HOME/licenses" ]] || return 1
  ls "$ANDROID_HOME/licenses" 2>/dev/null | grep -qE 'android-sdk-license|android-googletv-license'
}

if [[ -n "$SDKMANAGER_PATH" ]]; then
  if android_licenses_present; then
    record_state "sdk-licenses" "${fg[green]}✔${reset_color}" "already accepted"
  else
    info "Accepting Android SDK licenses"
    if yes | "$SDKMANAGER_PATH" --licenses >"$LICENSE_LOG" 2>&1; then
      record_state "sdk-licenses" "${fg[green]}✔${reset_color}" "accepted"
    else
      record_state "sdk-licenses" "${fg[yellow]}⚠${reset_color}" "see $LICENSE_LOG"
      warn "License acceptance reported issues (see $LICENSE_LOG)"
    fi
  fi
  "$SDKMANAGER_PATH" --update >"$SDKUPDATE_LOG" 2>&1 || warn "sdkmanager --update logged issues (see $SDKUPDATE_LOG)"
else
  record_state "sdk-licenses" "${fg[yellow]}⚠${reset_color}" "sdkmanager missing"
fi

after_install() {
  local key="$1" path="$2" package="$3"
  if [[ -e "$path" ]]; then
    record_state "$key" "${fg[green]}✔${reset_color}" "installed"
    return 0
  fi
  if [[ -z "$SDKMANAGER_PATH" ]]; then
    record_state "$key" "${fg[yellow]}⚠${reset_color}" "sdkmanager missing"
    return 1
  fi
  info "Ensuring $package"
  if "$SDKMANAGER_PATH" "$package" >/dev/null 2>&1; then
    record_state "$key" "${fg[green]}✔${reset_color}" "installed"
    return 0
  else
    record_state "$key" "${fg[yellow]}⚠${reset_color}" "install failed"
    return 1
  fi
}

after_install "platform-tools" "$ANDROID_HOME/platform-tools" "platform-tools"
after_install "platforms;android-34" "$ANDROID_HOME/platforms/android-34" "platforms;android-34"
after_install "build-tools;34.0.0" "$ANDROID_HOME/build-tools/34.0.0" "build-tools;34.0.0"

if command -v adb >/dev/null 2>&1; then
  devices=$(adb devices -l 2>/dev/null | sed '1d;/^\s*$/d')
  if [[ -n "$devices" ]]; then
    record_state "adb" "${fg[green]}✔${reset_color}" "devices detected"
  else
    record_state "adb" "${fg[yellow]}⚠${reset_color}" "no devices"
  fi
else
  record_state "adb" "${fg[yellow]}⚠${reset_color}" "not on PATH"
fi

section "iOS Tooling"
if command -v xcode-select >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; then
  record_state "xcode" "${fg[green]}✔${reset_color}" "$(xcode-select -p)"
else
  record_state "xcode" "${fg[yellow]}⚠${reset_color}" "CLI tools missing"
fi

if command -v pod >/dev/null 2>&1; then
  if pod --version >/dev/null 2>&1; then
    record_state "cocoapods" "${fg[green]}✔${reset_color}" "$(pod --version | head -n1)"
  else
    record_state "cocoapods" "${fg[yellow]}⚠${reset_color}" "pod error"
  fi
else
  info "Attempting CocoaPods install via sudo gem"
  if sudo gem install cocoapods >/dev/null 2>&1; then
    record_state "cocoapods" "${fg[green]}✔${reset_color}" "$(pod --version | head -n1)"
  else
    record_state "cocoapods" "${fg[yellow]}⚠${reset_color}" "install failed"
  fi
fi

section "Project Workspaces"
for lab in shopper brand; do
  lab_dir="$REPO_ROOT/frontend/nativescript/${lab}-lab"
  key="${lab}-lab"
  if [[ -d "$lab_dir" ]]; then
    record_state "$key" "${fg[green]}✔${reset_color}" "$lab_dir"
    if [[ ! -d "$lab_dir/node_modules" ]] && command -v npm >/dev/null 2>&1; then
      info "Installing npm dependencies for ${lab}-lab"
      if (cd "$lab_dir" && npm install >/dev/null 2>&1); then
        success "${lab}-lab dependencies installed"
      else
        warn "npm install failed for ${lab}-lab"
      fi
    fi
  else
    record_state "$key" "${fg[red]}✖${reset_color}" "missing"
  fi
done

section "NativeScript Doctor"
if command -v ns >/dev/null 2>&1; then
  if ns doctor android >/tmp/ns-doctor-android.log 2>&1; then
    record_state "ns-android" "${fg[green]}✔${reset_color}" "clean"
  else
    record_state "ns-android" "${fg[yellow]}⚠${reset_color}" "see /tmp/ns-doctor-android.log"
    warn "Android doctor issues logged to /tmp/ns-doctor-android.log"
  fi
  if ns doctor ios >/tmp/ns-doctor-ios.log 2>&1; then
    record_state "ns-ios" "${fg[green]}✔${reset_color}" "clean"
  else
    record_state "ns-ios" "${fg[yellow]}⚠${reset_color}" "see /tmp/ns-doctor-ios.log"
    warn "iOS doctor issues logged to /tmp/ns-doctor-ios.log"
  fi
else
  warn "Skipping ns doctor (NativeScript CLI unavailable)"
fi

section "Summary"
summary_row curl
summary_row unzip
summary_row brew
summary_row node
summary_row npm
summary_row ns
summary_row java
summary_row ANDROID_HOME
summary_row sdkmanager
summary_row "sdk-licenses"
summary_row 'platform-tools'
summary_row 'platforms;android-34'
summary_row 'build-tools;34.0.0'
summary_row adb
summary_row xcode
summary_row cocoapods
summary_row 'shopper-lab'
summary_row 'brand-lab'
summary_row 'ns-android'
summary_row 'ns-ios'

cat <<'NEXT'

Next actions:
  • Resolve any ✖ / ⚠ rows above; inspect $LICENSE_LOG, $SDKUPDATE_LOG, or /tmp/ns-doctor-*.log for full diagnostics.
  • Ensure an emulator or device is running before executing `ns run android|ios`.
  • Re-run this doctor after changes to confirm the environment is healthy.

NEXT
