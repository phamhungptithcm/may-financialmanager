#!/usr/bin/env bash
# Read-only / test-only gate. Never deploys or auto-installs packages.
set -uo pipefail
cd "$(dirname "$0")/.."
failures=0
blocked=0
run() { echo "> $*"; "$@" || { echo "FAIL: $*"; failures=$((failures+1)); }; }
block() { echo "BLOCKED: $*"; blocked=$((blocked+1)); }
python3 scripts/reference_preflight.py --strict || failures=$((failures+1))
python3 scripts/audit_traceability.py --release || failures=$((failures+1))
if [ -f docs/qa/reference-lock.json ]; then
  run python3 scripts/reference_preflight.py --strict --require-flow-export --lock-check
else
  block 'No reviewed docs/qa/reference-lock.json; baseline not pinned'
fi
if command -v flutter >/dev/null 2>&1 && [ -f pubspec.yaml ]; then
  run flutter analyze
  run flutter test
else
  block 'Flutter project/toolchain unavailable; flutter analyze/test not run'
fi
if [ -d functions ]; then
  if ! command -v npm >/dev/null 2>&1; then
    block 'npm unavailable for Functions checks'
  elif [ ! -f functions/package.json ]; then
    block 'functions/package.json missing'
  else
    if [ -d functions/node_modules ]; then
      echo '> (cd functions && npm run build --if-present)'
      (cd functions && npm run build --if-present) || failures=$((failures+1))
      echo '> (cd functions && npm test --if-present)'
      (cd functions && npm test --if-present) || failures=$((failures+1))
    else
      block 'Functions node_modules missing; no automatic npm install'
    fi
  fi
else
  block 'Functions project not found; backend tests not run'
fi
if [ -f firebase.json ] && command -v firebase >/dev/null 2>&1; then
  echo 'INFO: Firebase CLI detected; run Emulator security tests using the configured project-specific test command.'
else
  block 'Firebase Emulator checks not automatically run (missing firebase CLI/config)'
fi
printf 'Verification: failures=%s blocked=%s (BLOCKED != PASS)\n' "$failures" "$blocked"
if [ "$failures" -gt 0 ]; then exit 1; fi
if [ "$blocked" -gt 0 ]; then exit 2; fi
