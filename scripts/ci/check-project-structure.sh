#!/usr/bin/env bash
# check-project-structure.sh — Validate that required project directories and files exist.
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more mandatory paths missing
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
MISSING=0

require_file() {
  local path="$1" label="${2:-$path}" full
  full="$ROOT_DIR/$path"
  if [[ -f "$full" ]]; then
    echo "  ✓ $label ($path)"
  else
    echo "  ✗ MISSING: $label ($path)" >&2
    MISSING=1
  fi
}

require_dir() {
  local path="$1" label="${2:-$path}" full
  full="$ROOT_DIR/$path"
  if [[ -d "$full" ]]; then
    echo "  ✓ $label ($path)"
  else
    echo "  ✗ MISSING: $label ($path)" >&2
    MISSING=1
  fi
}

echo "=== Project Structure Check ==="

# Flutter app
require_dir "apps/mobile" "Flutter app root"
require_file "apps/mobile/pubspec.yaml" "Flutter pubspec"
require_dir "apps/mobile/lib" "Flutter lib/"
require_dir "apps/mobile/test" "Flutter test/"

# Firebase Functions
require_dir "functions" "Firebase Functions root"
require_file "functions/package.json" "Functions package.json"
require_file "functions/tsconfig.json" "Functions tsconfig.json"
require_dir "functions/src" "Functions src/"

# Firebase configuration
require_file "firebase.json" "Root firebase.json"
require_file "docs/firebase/database.rules.json" "RTDB rules"
require_file "docs/firebase/storage.rules" "Storage rules"

exit $MISSING
