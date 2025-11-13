#!/bin/bash
# restart_xcode.sh — safe helper to quit Xcode, remove temporary DerivedData created during session, and reopen workspace
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$REPO_ROOT/FitTwin-ios-enhanced-capture.xcworkspace"

echo "Quitting Xcode..."
osascript -e 'tell application "Xcode" to quit' || true

sleep 1

echo "Killing any remaining Xcode processes..."
pkill Xcode || true

sleep 1

echo "Removing temporary DerivedData dirs created by session: /tmp/DerivedData_fittwin_*"
rm -rf /tmp/DerivedData_fittwin_* || true

sleep 1

echo "Reopening workspace: $WORKSPACE"
open "$WORKSPACE"

echo "Done. Xcode should reopen shortly." 
