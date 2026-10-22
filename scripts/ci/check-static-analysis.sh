#!/usr/bin/env bash
# check-static-analysis.sh — Run flutter analyze.
#
# Exit codes:
#   0 — no fatal issues
#   1 — analysis found errors or command failed
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
APP_DIR="$ROOT_DIR/apps/mobile"

echo "=== Static Analysis ==="

if [[ ! -d "$APP_DIR/lib" ]]; then
  echo "  ⊘ SKIPPED — no Flutter lib/ directory found" >&2
  exit 0
fi

cd "$APP_DIR"
OUTPUT=$(flutter analyze --no-fatal-infos 2>&1) || {
  echo "  ✗ Static analysis errors:" >&2
  echo "$OUTPUT" >&2
  exit 1
}

# Count warnings vs errors for the summary
ERRORS=$(echo "$OUTPUT" | grep -c '^  [0-9]\+ issue' || true)
if [[ $ERRORS -gt 0 ]]; then
  echo "  ✗ Analysis reported issues (see above)" >&2
  exit 1
fi

echo "  ✓ Static analysis passed"
exit 0
