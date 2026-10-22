#!/usr/bin/env bash
# build-android.sh — Build Android APK and App Bundle.
#
# Exit codes:
#   0 — artifacts built successfully
#   1 — build failed or prerequisites missing
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APP_DIR="$ROOT_DIR/apps/mobile"
BUILD_OUTPUT="$ROOT_DIR/build/android"

mkdir -p "$BUILD_OUTPUT"

echo "=== Android Build ==="

if [[ ! -d "$APP_DIR/lib" ]]; then
  echo "  ⊘ SKIPPED — no Flutter lib/ directory found" >&2
  exit 0
fi

cd "$APP_DIR"

# flutter build apk
echo "  > flutter build apk --release"
flutter build apk --release || {
  echo "  ✗ APK build failed (see above)" >&2
  exit 1
}
cp build/app/outputs/flutter-apk/app.apk "$BUILD_OUTPUT/app-release.apk"

# flutter build appbundle
echo "  > flutter build appbundle --release"
flutter build appbundle --release || {
  echo "  ✗ App Bundle build failed (see above)" >&2
  exit 1
}
cp build/app/outputs/bundle/release/app-release.aab "$BUILD_OUTPUT/app-release.aab"

# Validate artifacts
for f in app-release.apk app-release.aab; do
  if [[ ! -s "$BUILD_OUTPUT/$f" ]]; then
    echo "  ✗ Artifact missing or empty: $BUILD_OUTPUT/$f" >&2
    exit 1
  fi
done

echo "  ✓ Android artifacts built and validated:"
echo "      $BUILD_OUTPUT/app-release.apk ($(du -h "$BUILD_OUTPUT/app-release.apk" | cut -f1))"
echo "      $BUILD_OUTPUT/app-release.aab ($(du -h "$BUILD_OUTPUT/app-release.aab" | cut -f1))"
exit 0
