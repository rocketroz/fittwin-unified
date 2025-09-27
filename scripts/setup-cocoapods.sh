#!/usr/bin/env zsh
set -euo pipefail

print_header(){
  printf "\n\033[1;34m[FitTwin] CocoaPods Setup\033[0m %s\n" "$1"
}

# 1. Remove gem-installed CocoaPods if present
print_header "Removing existing gem-based CocoaPods"
if gem list -i cocoapods >/dev/null 2>&1; then
  sudo gem uninstall cocoapods -aIx || true
fi

# 2. Remove leftover /usr/local/bin/pod if it exists
if [ -f /usr/local/bin/pod ]; then
  print_header "Removing /usr/local/bin/pod"
  sudo rm -f /usr/local/bin/pod
fi

# 3. Install CocoaPods via Homebrew
print_header "Installing CocoaPods via Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found; install Homebrew first." >&2
  exit 1
fi
brew install cocoapods

# 4. Initialize CocoaPods
print_header "Running pod setup"
pod setup

print_header "CocoaPods installation complete"
