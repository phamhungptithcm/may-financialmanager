#!/usr/bin/env bash
# generate-release-notes.sh — Generate professional release notes for a Mây release.
#
# Reads git history between the previous tag (or first commit) and HEAD.
# Outputs structured Markdown to stdout.
#
# Environment:
#   CI_ROOT       - repo root (auto-detected if missing)
#   BASE_REF      - branch/commit to diff against
#   APP_NAME      - display name (default: Mây Family Finance)
#   VERSION        - release version string (e.g. v0.1.0)
set -euo pipefail

ROOT_DIR="${CI_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT_DIR"

APP_NAME="Mây Family Finance"
VERSION="${VERSION:?VERSION is required; set env VERSION=vX.Y.Z}"

# Determine the comparison range.
if [[ -n "${BASE_REF:-}" ]]; then
  RANGE="${BASE_REF}..HEAD"
else
  LAST_TAG=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
  if [[ -n "$LAST_TAG" ]]; then
    RANGE="${LAST_TAG}..HEAD"
  else
    FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD | head -1)
    RANGE="${FIRST_COMMIT}..HEAD"
  fi
fi

TODAY=$(date +%Y-%m-%d)

# Fetch the changelog range.
if [[ ! -n "${RANGE:-}" ]]; then
  echo "ERROR: unable to determine comparison range." >&2
  exit 1
fi

CHANGES=$(git log --format='%s' "$RANGE" 2>/dev/null || true)

# Pull PR numbers from merge commits (e.g. "#123").
PR_NUMS=$(echo "$CHANGES" | grep -oP '#\d+' | sort -un | head -30 || true)

# Contributors.
CONTRIBUTORS=$(git log "$RANGE" --format='%an' 2>/dev/null | sort -u || true)

# Categorize commits.
FEATS=""
FIXES=""
IMPROVEMENTS=""
SECURITY=""
TECH=""
BREAKING=""
DOCS=""
CHORE=""

while IFS= read -r msg; do
  [[ -z "$msg" ]] && continue
  # Breaking changes first.
  if echo "$msg" | grep -qiE '^.*!:' || echo "$msg" | grep -qiE 'BREAKING CHANGE:'; then
    BREAKING="${BREAKING}• ${msg}"$'\n'
    continue
  fi
  # Match conventional commit prefixes (with optional scope): feat, fix, perf, docs, chore, refactor, security.
  if echo "$msg" | grep -qE '^feat(\(.*\))?:'; then
    FEATS="${FEATS}• ${msg}"$'\n'
  elif echo "$msg" | grep -qE '^fix(\(.*\))?:'; then
    FIXES="${FIXES}• ${msg}"$'\n'
  elif echo "$msg" | grep -qE '^perf(\(.*\))?:'; then
    IMPROVEMENTS="${IMPROVEMENTS}• ${msg}"$'\n'
  elif echo "$msg" | grep -qiE '^secur(ity)?(\(.*\))?:'; then
    SECURITY="${SECURITY}• ${msg}"$'\n'
  elif echo "$msg" | grep -qE '^refactor(\(.*\))?:'; then
    TECH="${TECH}• ${msg}"$'\n'
  elif echo "$msg" | grep -qE '^docs?(\(.*\))?:'; then
    DOCS="${DOCS}• ${msg}"$'\n'
  elif echo "$msg" | grep -qE '^chore(\(.*\))?:'; then
    CHORE="${CHORE}• ${msg}"$'\n'
  else
    IMPROVEMENTS="${IMPROVEMENTS}• ${msg}"$'\n'
  fi
done <<< "$CHANGES"

# --- Output release notes ---
echo "# ${APP_NAME} ${VERSION}"
echo ""
echo "Release Date: ${TODAY}"
echo ""

has_section() { echo -n "${!1:-}" | grep -q '.'; }

if has_section BREAKING; then
  echo "## Breaking Changes"
  echo ""
  echo "$BREAKING"
fi

if has_section FEATS; then
  echo "## New Features"
  echo ""
  echo "$FEATS"
fi

if has_section IMPROVEMENTS; then
  echo "## Improvements"
  echo ""
  echo "$IMPROVEMENTS"
fi

if has_section FIXES; then
  echo "## Bug Fixes"
  echo ""
  echo "$FIXES"
fi

if has_section SECURITY; then
  echo "## Security"
  echo ""
  echo "$SECURITY"
fi

if has_section TECH; then
  echo "## Technical Changes"
  echo ""
  echo "$TECH"
fi

if has_section DOCS || has_section CHORE; then
  SUMMARY=""
  has_section DOCS && SUMMARY="${SUMMARY}Documentation: ${DOCS}"
  has_section CHORE && SUMMARY="${SUMMARY}Chores: ${CHORE}"
  # Only emit if it's the sole non-empty section besides improvements.
fi

if [[ -n "${PR_NUMS:-}" ]]; then
  echo "## Merged Pull Requests"
  echo ""
  echo "$PR_NUMS" | while read -r pr; do
    echo "- ${pr}"
  done
  echo ""
fi

# Full changelog link.
if [[ -n "${LAST_TAG:-}" ]]; then
  echo "[Full Changelog: ${LAST_TAG}...${VERSION}](https://github.com/OWNER/MAY/compare/${LAST_TAG}...HEAD)"
else
  FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD | head -1)
  echo "[First Release — Full Commit History](https://github.com/OWNER/MAY/compare/${FIRST_COMMIT}...HEAD)"
fi
