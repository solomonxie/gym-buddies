#!/bin/sh
# Captures the store screenshots from the paired iPhone, using the DEBUG
# demo data (in memory — your real database is never opened).
# Unlock the phone and leave it on the home screen; it takes ~30 s.
#
# Usage: scripts/capture-screens.sh [out-dir]
set -e
cd "$(dirname "$0")/.."
OUT=${1:-/tmp/gymbuddy-shots}
DEVICE=${DEVICE:-$(xcrun devicectl list devices 2>/dev/null | grep 'physical' | grep -oE '[0-9A-F]{8}-[0-9A-F]{16}' | head -1)}
[ -n "$DEVICE" ] || { echo "No paired iPhone found"; exit 1; }
mkdir -p "$OUT"

xcodebuild -project GymBuddy.xcodeproj -scheme GymBuddy -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build -allowProvisioningUpdates -quiet build
xcrun devicectl device install app --device "$DEVICE" build/Build/Products/Debug-iphoneos/GymBuddy.app >/dev/null

shot() {
  xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
    com.example.gymbuddy -demo -screen "$2" >/dev/null
  sleep 3
  xcrun devicectl device capture screenshot --device "$DEVICE" --destination "$OUT/$1.png" >/dev/null
  echo "$1"
}
shot 01-session session
shot 02-resting resting
shot 03-train workouts
shot 04-progress logs
shot 05-trend trend
shot 06-exercise exercise
shot 07-summary summary
shot 08-library exercises
shot 09-set-running set
shot 10-treadmill treadmill
shot 11-background background
echo "Now: scripts/store-screenshots.sh $OUT"
