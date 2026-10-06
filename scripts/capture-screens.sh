#!/bin/sh
# Captures the store screenshots from the paired iPhone in Demo mode (`-demo`:
# a freshly seeded demo database — your real one is never opened).
# Unlock the phone and leave it on the home screen; it takes ~30 s.
#
# Usage: scripts/capture-screens.sh [out-dir]
set -e
cd "$(dirname "$0")/.."
OUT=${1:-/tmp/gymbuddy-shots}
DEVICE=${DEVICE:-$(xcrun devicectl list devices 2>/dev/null | grep 'physical' | grep -oE '[0-9A-F]{8}-[0-9A-F]{16}' | head -1)}
[ -n "$DEVICE" ] || { echo "No paired iPhone found"; exit 1; }
mkdir -p "$OUT"
APP_ID=$(sed -n 's/^APP_BUNDLE_ID *= *//p' Local.xcconfig)
[ -n "$APP_ID" ] || { echo "APP_BUNDLE_ID missing in Local.xcconfig"; exit 1; }

xcodebuild -project GymBuddy.xcodeproj -scheme GymBuddy -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build -allowProvisioningUpdates -quiet APP_STORE_REGION="${STORE:-us}" build
xcrun devicectl device install app --device "$DEVICE" build/Build/Products/Debug-iphoneos/GymBuddy.app >/dev/null

shot() {
  xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
    "$APP_ID" -demo -screen "$2" >/dev/null
  sleep 3
  xcrun devicectl device capture screenshot --device "$DEVICE" --destination "$OUT/$1.png" >/dev/null
  echo "$1"
}
shot 01-session session
shot 02-resting resting
shot 03-train train
shot 04-progress logs
shot 05-trend trend
shot 06-summary summary
shot 07-exercise exercise
shot 08-gyms gyms
shot 09-treadmill treadmill
shot 10-library exercises
echo "Now: scripts/store-screenshots.sh $OUT"
