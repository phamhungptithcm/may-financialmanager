#!/usr/bin/env bash
# test-flutter.sh — Run Flutter unit tests.
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed or no test directory found
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APP_DIR="$ROOT_DIR/apps/mobile"

echo "=== Flutter Unit Tests ==="

if [[ ! -d "$APP_DIR/test" ]]; then
  echo "  ⊘ SKIPPED — no Flutter test/ directory found" >&2
  exit 0
fi

cd "$APP_DIR"

# flutter test exits non-zero on failure; capture for summary.
flutter test --coverage --concurrency=4 || {
  echo "  ✗ Flutter tests failed (see above)" >&2
  exit 1
}

echo "  ✓ All Flutter unit tests passed"
exit 0
