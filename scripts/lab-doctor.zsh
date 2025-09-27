#!/usr/bin/env zsh
# FitTwin Lab Doctor: comprehensive environment report for shopper/brand NativeScript + Next + backend stacks.
set -euo pipefail

autoload -U colors && colors

ICON_OK="${fg[green]}OK${reset_color}"
ICON_WARN="${fg[yellow]}WARN${reset_color}"
ICON_FAIL="${fg[red]}FAIL${reset_color}"

typeset -A STATUS DETAILS

record() {
  local key="$1" state="$2" detail="$3"
  STATUS[$key]="$state"
  DETAILS[$key]="$detail"
}

header() {
  printf "\n${fg[cyan]}=== %s ===${reset_color}\n" "$1"
}

print_section() {
  local key
  for key in "$@"; do
    local state=${STATUS[$key]:-"${ICON_FAIL}"}
    local msg=${DETAILS[$key]:-"(no data)"}
    printf "%-24s %s %s\n" "$key" "$state" "$msg"
  done
}

warn() { printf "${fg[yellow]}[WARN]${reset_color} %s\n" "$1" >&2; }
fail() { printf "${fg[red]}[ERROR]${reset_color} %s\n" "$1" >&2; }

# --- Paths ---
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
SHOPPER_DIR="$REPO_ROOT/frontend/nativescript/shopper-lab"
BRAND_DIR="$REPO_ROOT/frontend/nativescript/brand-lab"

# --- Node ---
if command -v node >/dev/null 2>&1; then
  NODE_VERSION=$(node -v)
  record "node" "$ICON_OK" "$NODE_VERSION"
else
  record "node" "$ICON_FAIL" "node not found"
fi

if command -v npm >/dev/null 2>&1; then
  record "npm" "$ICON_OK" "$(npm -v)"
else
  record "npm" "$ICON_FAIL" "npm not found"
fi

# --- Java ---
JAVA_17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
if [[ -n "$JAVA_17_HOME" ]]; then
  JAVA_ACTUAL="$JAVA_17_HOME"
  JAVA_VERSION=$("$JAVA_17_HOME/bin/java" -version 2>&1 | head -n1)
  record "java" "$ICON_OK" "$JAVA_VERSION"
else
  record "java" "$ICON_FAIL" "Java 17 not detected"
fi

# --- Android SDK ---
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ -d "$ANDROID_HOME" ]]; then
  record "ANDROID_HOME" "$ICON_OK" "$ANDROID_HOME"
else
  record "ANDROID_HOME" "$ICON_FAIL" "Directory not found"
fi

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [[ -x "$SDKMANAGER" ]]; then
  record "sdkmanager" "$ICON_OK" "$(basename "$SDKMANAGER")"
else
  record "sdkmanager" "$ICON_WARN" "cmdline tools missing"
fi

# -- Check required packages if sdkmanager exists --
check_sdk_package() {
  local pkg="$1"
  if [[ -x "$SDKMANAGER" ]]; then
    if "$SDKMANAGER" --list | grep -q "$pkg"; then
      record "$pkg" "$ICON_OK" "installed"
    else
      record "$pkg" "$ICON_WARN" "missing"
    fi
  else
    record "$pkg" "$ICON_WARN" "sdkmanager unavailable"
  fi
}

check_sdk_package "platform-tools"
check_sdk_package "platforms;android-34"
check_sdk_package "build-tools;34.0.0"

# --- adb ---
if command -v adb >/dev/null 2>&1; then
  DEVICES=$(adb devices -l | sed '1d; /^(.*device\s*)$/!d' 2>/dev/null || true)
  [[ -n "$DEVICES" ]] && record "adb" "$ICON_OK" "$(echo "$DEVICES" | tr "\n" ';')" || record "adb" "$ICON_WARN" "No devices listed"
else
  record "adb" "$ICON_FAIL" "adb not found"
fi

# --- NativeScript CLI ---
if command -v ns >/dev/null 2>&1; then
  record "ns" "$ICON_OK" "$(ns --version 2>/dev/null)"
else
  record "ns" "$ICON_FAIL" "NativeScript CLI missing"
fi

# --- iOS tooling ---
if command -v xcode-select >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; then
  record "xcode-select" "$ICON_OK" "$(xcode-select -p)"
else
  record "xcode-select" "$ICON_WARN" "Xcode CLI tools missing"
fi

if command -v pod >/dev/null 2>&1; then
  record "cocoapods" "$ICON_OK" "$(pod --version)"
else
  record "cocoapods" "$ICON_WARN" "pod not found"
fi

# --- Stack services ---
check_port() {
  local port="$1"
  if lsof -i ":$port" >/dev/null 2>&1; then
    record "port:$port" "$ICON_OK" "listening"
  else
    record "port:$port" "$ICON_WARN" "no process"
  fi
}

check_port 3000
check_port 3001
check_port 3100

# --- Project directories ---
[[ -d "$SHOPPER_DIR" ]] && record "shopper-lab" "$ICON_OK" "$SHOPPER_DIR" || record "shopper-lab" "$ICON_FAIL" "missing"
[[ -d "$BRAND_DIR" ]]   && record "brand-lab"   "$ICON_OK" "$BRAND_DIR"   || record "brand-lab"   "$ICON_FAIL" "missing"

# --- Output ---
header "System"
print_section node npm java ANDROID_HOME sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" adb ns xcode-select cocoapods

header "Ports"
print_section port:3000 port:3001 port:3100

header "Projects"
print_section shopper-lab brand-lab

cat <<INFO

Next Steps:
  • ${fg[cyan]}If any rows show WARN/FAIL, address them before running the lab.${reset_color}
  • To deploy: 
      ./scripts/run-ns-android.zsh shopper
      ./scripts/run-ns-android.zsh brand
  • Keep node scripts/dev-stack.mjs running for backend + web.

INFO
