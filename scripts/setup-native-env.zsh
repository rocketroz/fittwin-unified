#!/usr/bin/env zsh
set -euo pipefail

print_header() {
  printf "\n\033[1;34m[FitTwin Setup]\033[0m %s\n" "$1"
}

error_exit() {
  printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2
  exit 1
}

# 1. NativeScript CLI
if ! command -v ns >/dev/null 2>&1; then
  print_header "Installing NativeScript CLI (npm install -g nativescript)"
  npm install -g nativescript || error_exit "Failed to install NativeScript CLI"
else
  print_header "NativeScript CLI already installed"
fi

# 2. Xcode command-line tools
if command -v xcode-select >/dev/null 2>&1; then
  XCODE_PATH="/Applications/Xcode.app/Contents/Developer"
  if [ -d "$XCODE_PATH" ]; then
    print_header "Configuring Xcode command-line tools"
    sudo xcode-select --switch "$XCODE_PATH" || error_exit "xcode-select failed"
    sudo xcodebuild -license accept || error_exit "Failed to accept Xcode license"
  else
    print_header "⚠️  Xcode not found at $XCODE_PATH (skipping)"
  fi
fi

# 3. CocoaPods
if ! command -v pod >/dev/null 2>&1; then
  print_header "Installing CocoaPods"
  sudo gem install cocoapods || error_exit "Failed to install CocoaPods"
else
  print_header "CocoaPods already installed"
fi

# 4. Android SDK
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
mkdir -p "$ANDROID_HOME"
print_header "Android SDK root: $ANDROID_HOME"

find_sdkmanager() {
  if command -v sdkmanager >/dev/null 2>&1; then
    echo "$(command -v sdkmanager)"
    return 0
  fi
  local candidate
  candidate=$(find "$ANDROID_HOME" -name sdkmanager -perm +111 2>/dev/null | head -n 1)
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return 0
  fi
  return 1
}

SDKMANAGER=$(find_sdkmanager) || {
  print_header "sdkmanager not found; downloading Android command-line tools"
  TMPDIR=$(mktemp -d)
  CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
  CMDLINE_ZIP="$TMPDIR/cmdline-tools.zip"
  curl -L "$CMDLINE_URL" -o "$CMDLINE_ZIP" || error_exit "Failed to download command line tools"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -q "$CMDLINE_ZIP" -d "$TMPDIR" || error_exit "Failed to unzip command line tools"
  # Google ships them as cmdline-tools; rename to latest for NativeScript expectations
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$TMPDIR/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" || error_exit "Failed to move command line tools"
  rm -rf "$TMPDIR"
  SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  chmod +x "$SDKMANAGER"
}

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  print_header "Installing Android command-line tools"
  "$SDKMANAGER" "cmdline-tools;latest" || error_exit "Failed to install cmdline tools"
fi

export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Ensure a compatible JDK (prefer 17) before running sdkmanager
ensure_jdk() {
  if /usr/libexec/java_home -V 2>&1 | grep -q '17'; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    print_header "JAVA_HOME set to $JAVA_HOME (Java 17)"
  elif /usr/libexec/java_home -V 2>&1 | grep -q '21'; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 21)
    print_header "JAVA_HOME set to $JAVA_HOME (Java 21)"
  elif /usr/libexec/java_home -V 2>&1 | grep -q '11'; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 11)
    print_header "JAVA_HOME set to $JAVA_HOME (Java 11)"
  else
    print_header "Installing Temurin JDK (17) via Homebrew"
    if command -v brew >/dev/null 2>&1; then
      if ! brew install --cask temurin@17 >/dev/null 2>&1; then
        print_header "temurin@17 cask unavailable; installing latest temurin"
        brew install --cask temurin || error_exit "Failed to install Temurin JDK"
      fi
      if /usr/libexec/java_home -V 2>&1 | grep -q '17'; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
      elif /usr/libexec/java_home -V 2>&1 | grep -q '21'; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 21)
      elif /usr/libexec/java_home -V 2>&1 | grep -q '11'; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
      else
        export JAVA_HOME=$(/usr/libexec/java_home)
      fi
      print_header "JAVA_HOME set to $JAVA_HOME"
    else
      error_exit "Homebrew not found; install JDK 11 manually"
    fi
  fi
  export PATH="$JAVA_HOME/bin:$PATH"
}

ensure_jdk

print_header "Accepting Android SDK licenses"
yes | sdkmanager --licenses >/dev/null || error_exit "Failed to accept SDK licenses"

print_header "Installing required Android SDK packages"
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" || error_exit "Failed to install Android SDK packages"

# 6. Doctor checks
print_header "Running ns doctor ios"
ns doctor ios || print_header "ns doctor ios completed with warnings"

print_header "Running ns doctor android"
ns doctor android || print_header "ns doctor android completed with warnings"

print_header "Native environment bootstrap complete"
