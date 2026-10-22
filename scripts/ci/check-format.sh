#!/usr/bin/env bash
# check-format.sh — Run dart format on the Flutter app.
#
# Exit codes:
#   0 — all files formatted correctly (no output = clean)
#   1 — formatting issues found or command failed
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APP_DIR="$ROOT_DIR/apps/mobile"

echo "=== Dart Format Check ==="

if [[ ! -d "$APP_DIR/lib" ]]; then
  echo "  ⊘ SKIPPED — no Flutter lib/ directory found" >&2
  exit 0
fi

cd "$APP_DIR"
OUTPUT=$(dart format --set-exit-code lib/ --line-length 120 2>&1) || {
  echo "  ✗ Formatting issues detected:" >&2
  echo "$OUTPUT" >&2
  exit 1
}

echo "  ✓ All files formatted correctly (line-length 120)"
exit 0
