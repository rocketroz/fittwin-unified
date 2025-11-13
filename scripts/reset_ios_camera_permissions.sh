#!/usr/bin/env bash

set -euo pipefail

# Resets then re-grants iOS simulator camera permissions for the FitTwin app.
# Usage:
#   scripts/reset_ios_camera_permissions.sh            # affects currently booted simulator
#   scripts/reset_ios_camera_permissions.sh <sim-udid> # target specific simulator
#
# After this script completes, re-run the app from Xcode so the camera prompt
# appears again on first launch.

BUNDLE_ID="com.lauratornga.fittwin.app"
DEVICE_ID="${1:-booted}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "[reset-camera] xcrun not found. Install Xcode command line tools (xcode-select --install)." >&2
  exit 1
fi

echo "[reset-camera] Target simulator: ${DEVICE_ID}"
echo "[reset-camera] Resetting camera permissions for ${BUNDLE_ID}…"
xcrun simctl privacy "${DEVICE_ID}" reset camera "${BUNDLE_ID}" || {
  echo "[reset-camera] Failed to reset camera permission (is the simulator booted?)." >&2
  exit 1
}

echo "[reset-camera] Granting camera permission so iOS will re-prompt on next launch…"
xcrun simctl privacy "${DEVICE_ID}" grant camera "${BUNDLE_ID}" || {
  echo "[reset-camera] Failed to grant camera permission." >&2
  exit 1
}

echo "[reset-camera] Done. Relaunch the app from Xcode to trigger a fresh camera prompt."
