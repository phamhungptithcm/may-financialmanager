#!/usr/bin/env bash
# calculate-version.sh — Determine the next semantic version from git history.
#
# Outputs a version string like "v0.1.0" to stdout.
# If no release-worthy changes are detected (only docs/test/chore), exits 2.
#
# Environment:
#   CI_ROOT       - repo root (auto-detected if missing)
#   BASE_REF      - branch/commit to diff against (defaults: previous tag or main)
#   INITIAL_VERSION - override for first release (default: v0.1.0)
#
# Exit codes:
#   0 — version determined (printed to stdout)
#   1 — error (git failure, no repo, etc.)
#   2 — no release-worthy changes detected
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT_DIR"

INITIAL_VERSION="${INITIAL_VERSION:-v0.1.0}"

# Ensure we are in a git repo.
if ! git rev-parse --git-dir &>/dev/null; then
  echo "ERROR: not a git repository" >&2
  exit 1
fi

# Determine the range to inspect for changes.
if [[ -n "${BASE_REF:-}" ]]; then
  RANGE="${BASE_REF}..HEAD"
else
  # Try previous tag first; fall back to initial commit.
  LAST_TAG=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
  if [[ -n "$LAST_TAG" ]]; then
    RANGE="${LAST_TAG}..HEAD"
  else
    FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD | head -1)
    RANGE="${FIRST_COMMIT}..HEAD"
  fi
fi

# Collect commit messages in the range (conventional-commit prefixes).
COMMIT_MSGS=""
if [[ -n "${RANGE:-}" ]]; then
  COMMIT_MSGS=$(git log --format='%s' "$RANGE" 2>/dev/null || true)
fi

if [[ -z "${COMMIT_MSGS:-}" ]]; then
  echo "ERROR: no commits in range $RANGE" >&2
  exit 1
fi

# Categorize changes.
HAS_BREAKING=0
HAS_FEAT=0
HAS_FIX=0

while IFS= read -r msg; do
  # Check for breaking change marker.
  if echo "$msg" | grep -qiE '^.*!:' || echo "$msg" | grep -qiE 'BREAKING CHANGE:'; then
    HAS_BREAKING=1
    continue
  fi
  # Match conventional commit prefixes: feat, fix (with optional scope)
  if echo "$msg" | grep -qE '^feat(\(.*\))?:'; then
    HAS_FEAT=1
  elif echo "$msg" | grep -qE '^fix(\(.*\))?:'; then
    HAS_FIX=1
  fi
done <<< "$COMMIT_MSGS"

# Determine bump.
if [[ $HAS_BREAKING -ne 0 ]]; then
  # For pre-1.0, a breaking change bumps MINOR; at 1.0+ it bumps MAJOR.
  echo "vMAJOR.NOTYET"  # placeholder — handled by the caller for pre-1.0.
elif [[ $HAS_FEAT -ne 0 ]]; then
  # Bump minor: find last *.X.* tag and increment X.
  LAST_MINOR=$(git tag -l 'v*.*.*' | grep -oP 'v\K\d+\.\d+' | sort -t. -k1,1n -k2,2n | tail -1 || true)
  if [[ -n "$LAST_MINOR" ]]; then
    MAJOR="${LAST_MINOR%%.*}"
    MINOR="${LAST_MINOR##*.}"
    NEW_MINOR=$(( MINOR + 1 ))
    echo "v${MAJOR}.${NEW_MINOR}.0"
  else
    # No tags yet; start at v0.2.0 for first feature release (after initial scaffolding).
    echo "v0.2.0"
  fi
elif [[ $HAS_FIX -ne 0 ]]; then
  LAST_PATCH=$(git tag -l 'v*.*.*' | grep -oP 'v\K\d+\.\d+\.\d+' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 || true)
  if [[ -n "$LAST_PATCH" ]]; then
    VERSION="${LAST_PATCH#v}"
    MAJOR="${VERSION%%.*}"; REST="${VERSION#*.}"
    MINOR="${REST%%.*}"; PATCH="${REST##*.}"
    NEW_PATCH=$(( PATCH + 1 ))
    echo "v${MAJOR}.${MINOR}.${NEW_PATCH}"
  else
    echo "v0.1.1"
  fi
else
  # No release-worthy changes (docs, test, chore, refactor).
  exit 2
fi

exit 0
