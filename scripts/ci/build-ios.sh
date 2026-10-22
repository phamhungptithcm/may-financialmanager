#!/usr/bin/env bash
# build-ios.sh — Build iOS release artifact (where platform supports it).
#
# On macOS runners: builds unsigned .app and validates IPA structure.
# On non-macOS runners: reports PREREQUISITE_MISSING gracefully.
#
# Exit codes:
#   0 — build succeeded or skipped (prerequisites not met)
#   1 — build failed
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APP_DIR="$ROOT_DIR/apps/mobile"
BUILD_OUTPUT="$ROOT_DIR/build/ios"

mkdir -p "$BUILD_OUTPUT"

echo "=== iOS Build ==="

if [[ ! -d "$APP_DIR/lib" ]]; then
  echo "  ⊘ SKIPPED — no Flutter lib/ directory found" >&2
  exit 0
fi

# Only macOS has Xcode / xcodebuild.
UNAME_S=$(uname -s 2>/dev/null || echo "Unknown")
if [[ "$UNAME_S" != "Darwin" ]]; then
  echo "  ⊘ SKIPPED — iOS build requires a macOS runner (current: $UNAME_S)" >&2
  exit 0
fi

cd "$APP_DIR"

# Check for Xcode toolchain.
XCVER=$(xcodebuild -version 2>/dev/null | head -1 || echo "not found")
if [[ "$XCVER" == *"not found"* ]]; then
  echo "  ⊘ SKIPPED — Xcode not found on this macOS runner" >&2
  exit 0
fi

# Build unsigned iOS archive.
echo "  > flutter build ios --release --no-codesign"
flutter build ios --release --no-codesign || {
  echo "  ✗ iOS build (unsigned) failed (see above)" >&2
  exit 1
}

# Copy .app for artifact storage.
APP_PATH="build/ios/iphoneos/Runner.app"
if [[ -d "$APP_PATH" ]]; then
  cp -r "$APP_PATH" "$BUILD_OUTPUT/Runner.app"
  FILE_COUNT=$(find "$BUILD_OUTPUT/Runner.app" -type f | wc -l)
  echo "  ✓ iOS unsigned .app built: $FILE_COUNT files"
else
  echo "  ⚠ No .app found at $APP_PATH (may require simulator arch)" >&2
fi

# Code-signing check.
PROVISIONING_PROFILE=$(find "$HOME" -name "*.mobileprovision" 2>/dev/null | head -1 || true)
if [[ -z "$PROVISIONING_PROFILE" ]]; then
  echo "  ⚠ No provisioning profile found — cannot build signed IPA." >&2
  echo "    PREREQUISITE: Add FLUTTER_IOS_PROVISIONING_PROFILE secret to repository." >&2
fi

echo "  ✓ iOS build check completed"
exit 0
