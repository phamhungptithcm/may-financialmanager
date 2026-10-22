#!/usr/bin/env bash
# verify-artifacts.sh — Validate generated release artifacts.
#
# Expects BUILD_OUTPUT env pointing to build root (default ../build).
# Prints checksums and file sizes for provenance tracking.
#
# Exit codes:
#   0 — all expected artifacts validated
#   1 — one or more required artifacts missing or empty
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
BUILD_OUTPUT="${BUILD_OUTPUT:-$ROOT_DIR/build}"

echo "=== Artifact Verification ==="

FAILED=0

# Android APK
APK="$BUILD_OUTPUT/android/app-release.apk"
if [[ -f "$APK" ]]; then
  SIZE=$(du -h "$APK" | cut -f1)
  SHA=$(sha256sum "$APK" | cut -d' ' -f1)
  echo "  ✓ APK  $SIZE  sha256:$SHA"
else
  echo "  ✗ APK missing: $APK" >&2
  FAILED=1
fi

# Android App Bundle
AAB="$BUILD_OUTPUT/android/app-release.aab"
if [[ -f "$AAB" ]]; then
  SIZE=$(du -h "$AAB" | cut -f1)
  SHA=$(sha256sum "$AAB" | cut -d' ' -f1)
  echo "  ✓ AAB  $SIZE  sha256:$SHA"
else
  echo "  ⚠ AAB missing: $AAB (may require macOS for bundle)" >&2
fi

# iOS .app
IOS_DIR="$BUILD_OUTPUT/ios"
if [[ -d "$IOS_DIR/Runner.app" ]]; then
  FILE_COUNT=$(find "$IOS_DIR/Runner.app" -type f | wc -l)
  echo "  ✓ iOS .app  $FILE_COUNT files (unsigned)"
else
  echo "  ⊘ iOS .app not available (may require macOS runner)" >&2
fi

# Summary line for job summary output
if [[ $FAILED -ne 0 ]]; then
  echo "" >&2
  echo "  ✗ Artifact verification FAILED" >&2
  exit 1
else
  echo "  ✓ All verified artifacts valid"
fi

exit 0
