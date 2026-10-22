#!/usr/bin/env bash
# test-functions.sh — Run Firebase Functions lint, typecheck, and unit tests.
#
# Exit codes:
#   0 — all checks passed (or nothing to run)
#   1 — one or more checks failed
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
FUNCS_DIR="$ROOT_DIR/functions"

echo "=== Functions: Type Check + Lint ==="

if [[ ! -d "$FUNCS_DIR/src" ]]; then
  echo "  ⊘ SKIPPED — no Functions src/ directory found" >&2
  exit 0
fi

cd "$FUNCS_DIR"

# TypeScript type check
echo "  > tsc --noEmit"
npx tsc --noEmit || {
  echo "  ✗ TypeScript type-check failed (see above)" >&2
  exit 1
}
echo "  ✓ TypeScript type-check passed"

# ESLint
echo "  > eslint src/ --ext .ts"
npx eslint src/ --ext .ts || {
  echo "  ✗ ESLint failed (see above)" >&2
  exit 1
}
echo "  ✓ ESLint passed"

# Unit tests
TESTS_DIR="$FUNCS_DIR/test"
if [[ -d "$TESTS_DIR" ]] && ls "$TESTS_DIR"/*.ts &>/dev/null; then
  echo "=== Functions: Unit Tests ==="
  npm test || {
    echo "  ✗ Functions unit tests failed (see above)" >&2
    exit 1
  }
  echo "  ✓ All Functions unit tests passed"
else
  echo "  ⊘ SKIPPED — no Functions test files found" >&2
fi

echo ""
echo "✓ Functions checks completed"
exit 0
