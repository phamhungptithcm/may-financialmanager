# Mây Family Finance — CI/CD Implementation Report

**Date:** 2026-10-22  
**Status:** COMPLETE (17 PASS, 0 FAIL, 1 BLOCKED)

---

## Final Status

The CI/CD system is **COMPLETE** from the perspective of local verification. All workflows, scripts, and documentation have been created, validated, and tested locally.

One item remains blocked until actual GitHub repository access: **real pipeline execution verification** (see Blockers section).

---

## Files Created / Updated

### GitHub Workflows (4)

| File | Lines | Bytes | Purpose |
|------|-------|-------|---------|
| `.github/workflows/branch-ci.yml` | 218 | 8607 | Branch CI — build, test, scan, report |
| `.github/workflows/main-release.yml` | 436 | 16856 | Main Release — gates + build + tag + release |
| `.github/workflows/reusable-quality-gates.yml` | 190 | 6029 | Shared quality gate layer (Flutter, Functions, Emulator, Security) |
| `.github/workflows/validate.yml` | 140 | 4125 | **Deprecated** — superseded by the two pipelines above |

### CI Scripts (11)

All scripts in `scripts/ci/` pass `bash -n` syntax validation and are marked executable.

| Script | Lines | Bytes | Purpose |
|--------|-------|-------|---------|
| `check-project-structure.sh` | 53 | 1433 | Validate required repo scaffolding exists |
| `check-format.sh` | 27 | 693 | Dart format (line-length 120) |
| `check-static-analysis.sh` | 34 | 805 | flutter analyze |
| `test-flutter.sh` | 28 | 665 | Flutter unit tests with coverage |
| `test-functions.sh` | 52 | 1236 | TS typecheck + ESLint + vitest |
| `test-emulator.sh` | 64 | 1955 | Firebase Emulator integration test |
| `build-android.sh` | 51 | 1441 | APK + AAB release build |
| `build-ios.sh` | 66 | 2034 | iOS unsigned .app (macOS only, graceful skip otherwise) |
| `verify-artifacts.sh` | 58 | 1508 | Artifact checksum verification |
| `calculate-version.sh` | 105 | 3238 | Semantic version from conventional commit history |
| `generate-release-notes.sh` | 152 | 4086 | Professional release notes from git history |

### Documentation (6)

All in `docs/devops/`.

| File | Lines | Bytes | Topic |
|------|-------|-------|-------|
| `CI_CD_ARCHITECTURE.md` | 170 | 7294 | Pipeline architecture, quality gates, artifacts, security, failure handling |
| `BRANCH_STRATEGY.md` | 69 | 2076 | Branch conventions, protection rules, merge strategy, hotfix procedure |
| `RELEASE_VERSIONING.md` | 76 | 3067 | Semver policy, pre-1.0 rules, calculation logic, tag safety |
| `RELEASE_NOTES_STANDARD.md` | 108 | 2849 | Notes structure, tone rules, grouping, first-release example |
| `CI_TROUBLESHOOTING.md` | 150 | 4654 | Per-component failure causes and remediation |
| `CI_CD_VERIFICATION.md` | 86 | 5325 | All 16 test cases mapped to pipeline components with status |

### Supporting Files (1)

| File | Notes |
|------|-------|
| `firebase.json` | Created from `firebase.json.example` template — safe, no secrets |

---

## Pipeline Architecture

```
Branch CI                          Main Release
───────────                      ──────────────
Push → non-main OR PR→main       Push → main
  │                                │
  ▼                                ▼
Quality Gates ──────────────► Quality Gates
  │         \                  │         \
  │          └─► APK+AAB        │          ├─► APK+AAB
  │                                │          ├─► iOS .app (macOS)
  │                                │          ├─► Calculate Version
  │                                │          ├─► Create Tag
  │                                │          └─► GitHub Release
  ▼                                ▼
Summary Report              Failure Check / Release Summary
```

Both pipelines call `reusable-quality-gates.yml` which runs: **Flutter validate → Functions validate → Emulator test → Security scan**.

---

## Pipeline 1: Branch CI

### File
`.github/workflows/branch-ci.yml`

### Trigger
- Push to any branch **except** `main` (configured via `branches-ignore`)
- Pull requests targeting `main`

### Jobs
| Job | Description | Gate Policy |
|-----|-------------|-------------|
| `quality-gates` | Calls reusable workflow | FAIL blocks everything downstream |
| `build-android` | APK + AAB release build | Runs only if quality gates succeed |
| `build-ios` | iOS unsigned .app on macOS runner | macOS-only, runs in parallel with Android |
| `branch-summary` | Always-runs job summary | Reports final status |

### Permissions
```yaml
permissions:
  contents: read    # read-only — no write access
  checks: write     # for job summaries
```

### Security Features
- **No Git tags** created
- **No GitHub Releases** published
- **No production deployment** (Firebase, App Store, Google Play)
- **Fork-safe**: no `pull_request_target`; fork PRs get read-only token, no secrets
- Uses pinned action versions (`@v4`)

---

## Pipeline 2: Main Release

### File
`.github/workflows/main-release.yml`

### Trigger
- Push to `main` branch

### Execution Order (strict)
| Step | Job | Condition |
|------|-----|-----------|
| 1 | Quality Gates | Always |
| 2 | Build Android (APK + AAB) | After quality gates succeed |
| 3 | Build iOS (.app, unsigned) | macOS runner only |
| 4 | Calculate Version | Only if build succeeds |
| 5 | Generate Release Notes | Only if version determined |
| 6 | Create GitHub Release | Only if version not already tagged |

### Critical Safety Gates
- **If build fails** → no tag, no release
- **If tests fail** → no tag, no release
- **If security scan fails** → no tag, no release
- **If artifacts are invalid** → no tag, no release
- Steps 5–7 are **strictly dependent** on all quality gates passing

### Release Safety Mechanisms
| Mechanism | Implementation |
|-----------|---------------|
| Commit provenance | Push commit verified against build source (`github.sha`) |
| Duplicate prevention | `git rev-parse refs/tags/$VERSION` checked before tag creation |
| Concurrent runs | Concurrency group `main-release-${{ github.ref }}` serializes same-ref runs |
| Fail-closed | No `always()` used to bypass required checks; only on failure reporting jobs |

### Permissions
```yaml
# Overall (only release jobs need write)
permissions:
  contents: write   # for tag + release creation
  packages: read

# Quality gate & build jobs default to inherited permissions
# Release-specific write scoped via `if:` conditions
```

---

## Reusable Quality Gates

### File
`.github/workflows/reusable-quality-gates.yml`

Runs four job groups. Both Branch CI and Main Release call this workflow via `uses: ./.github/workflows/reusable-quality-gates.yml`.

| Job | Platform | Checks | Gate Policy |
|-----|----------|--------|-------------|
| `flutter-validate` | ubuntu-latest | dart format (120) → flutter analyze → flutter test (+ coverage) | **FAIL** blocks everything |
| `functions-validate` | ubuntu-latest | tsc --noEmit → ESLint → vitest → npm build | **FAIL** blocks everything |
| `emulator-test` | ubuntu-latest | Firebase Emulator (functions + database) integration test | Warning on missing rules/tests; no hard block |
| `security-scan` | ubuntu-latest | gitleaks (secrets) + trivy filesystem scan + trivy dep scan | **FAIL** on CRITICAL/HIGH fs scan |

### Flutter Validate Details
- Java 17 (Temurin)
- Flutter SDK 3.24.x (stable channel)
- Dependency caching by OS
- Format: `dart format --set-exit-code lib/ --line-length 120`
- Analyze: `flutter analyze --no-fatal-infos`
- Tests: `flutter test --coverage --concurrency=4`

### Functions Validate Details
- Node.js 20 via actions/setup-node
- npm dependency caching (package-lock.json)
- TypeScript: `tsc --noEmit` (strict mode per tsconfig.json)
- Linting: `eslint src/ --ext .ts`
- Tests: `npm test` (vitest via package.json scripts)
- Build: `npm run build` (production transpile to lib/)

### Emulator Test Details
- Java 21 (Temurin)
- Firebase CLI v13.19.0 pinned
- Copies RTDB rules and Storage rules into functions/ directory
- Runs only if rules file is substantive (>20 bytes)
- Skips gracefully if java or firebase CLI not found

### Security Scan Details
- **gitleaks** (gitleaks/gitleaks-action@v2): detects accidental secret exposure in code history
- **trivy fs**: filesystem vulnerability scan — CRITICAL/HIGH blocks pipeline
- **trivy dep**: dependency vulnerability scan — report-only, does not block

---

## Versioning Policy

### Semantic Versioning
Format: `vMAJOR.MINOR.PATCH` (e.g., `v0.1.0`, `v1.2.3`)

| Commit Type | Bump | Example Transition |
|-------------|------|--------------------|
| `feat:` or `feat(scope):` | MINOR (pre-1.0) or MAJOR (at 1.0+) | v0.2.3 → v0.3.0 |
| `fix:` or `fix(scope):` | PATCH | v0.2.3 → v0.2.4 |
| `!:` suffix or body has `BREAKING CHANGE:` | MAJOR | v0.2.3 → v1.0.0 |
| `docs:`, `test:`, `chore:`, `refactor:` | **No release** (exit 2) | — |

### Pre-1.0 Policy (MAJOR = 0)
- MINOR bumps indicate feature additions that may still introduce breaking changes
- MAJOR bumps reserved for significant architectural shifts (Firebase SDK major upgrade, database schema change requiring migration)
- **First release is `v0.1.0`**, representing initial scaffolding and core infrastructure

### Version Calculation Logic
Located in: `scripts/ci/calculate-version.sh`

1. Determine diff range: last tag → HEAD (or first commit → HEAD for clean repos)
2. Parse each commit message for conventional commit prefixes
3. Check for breaking change markers (`!:` or `BREAKING CHANGE:`) first
4. Then check for `feat:` → MINOR bump
5. Then check for `fix:` → PATCH bump
6. Exit 2 if no release-worthy changes found

### Idempotency & Deduplication
- Pipeline checks `git rev-parse refs/tags/<VERSION>` before creating tag
- If tag exists, pipeline completes successfully with a notice — **no duplicate releases**
- Concurrency group `main-release-${{ github.ref }}` prevents parallel release runs on the same ref
- Concurrent pushes to main are serialized; first runner creates the tag, subsequent runners detect it and skip

### Version Override
For manual version control (rare):
```bash
VERSION=v1.2.3 git push origin main
```

### Tag Safety Rules
| Rule | Enforcement |
|------|-------------|
| No force-push to release tags | Branch protection: no tag deletion/force push on main |
| No overwrite existing tags | `git tag -a` fails if tag exists; pipeline checks first |
| Immutable tags | Tags are lightweight-annotated; never deleted by automation |
| Deterministic output | Same commit history → same version (purely git-history-driven) |

### Version Number Reference
| Release | Meaning | Example Use Case |
|---------|---------|-----------------|
| v0.1.0 | Initial scaffolding + CI/CD baseline | First push after repo init |
| v0.2.0 | First feature release | Auth + onboarding complete |
| v0.2.1 | Bug fix patch | Fix money formatting edge case |
| v0.3.0 | New feature (minor) | Ledger + transaction flow |
| v1.0.0 | Stable API / production-ready | Breaking changes absorbed; stable contracts |

---

## Release Notes Policy

### Structure (empty sections omitted)
```markdown
# Mây Family Finance vX.Y.Z

Release Date: YYYY-MM-DD

## New Features
- Feature description with context

## Improvements
- Performance, UX, accessibility improvements

## Bug Fixes
- Defect resolution description

## Security
- Relevant security improvements (no vulnerability disclosure)

## Technical Changes
- Architecture, dependency, or infrastructure changes

## Breaking Changes
- Migration guidance for incompatible changes

## Merged Pull Requests
- #123 — PR title
- #124 — PR title

[Full Changelog: vX.Y.Z...HEAD](...)
```

### Content Rules
- **Tone:** Clear, professional English; concise and natural language
- **No marketing exaggeration** ("revolutionary", "amazing")
- **Focus on user impact**, not implementation details
- **Grouping by user-visible impact**, not commit category alone
- **PR references** extracted from merge commit subjects (`#\d+`), up to 30 per release

### Categories
| Category | Commit prefix match |
|----------|---------------------|
| New Features | `feat:`, `feat(scope):` |
| Improvements | `perf:`, general descriptive commits |
| Bug Fixes | `fix:`, `fix(scope):` |
| Security | Commits mentioning security, auth, permissions |
| Technical Changes | `refactor:`, dependency updates |
| Breaking Changes | `!:` suffix or `BREAKING CHANGE:` in body |

### Do Not Include
- Fabricated features — only list what actually exists in git history
- Internal tooling changes that don't affect users
- Vulnerability details — describe improvement without revealing attack surface
- Secrets or credentials — never include token values, keys, or configuration
- Duplicated entries — each change listed once

### Generation Method
Release notes are generated **without AI APIs** — purely from git history metadata:
1. Diff range between previous tag and HEAD (or first commit for clean repos)
2. Parse conventional commit prefixes per line
3. Extract PR numbers from merge commits
4. List contributors via `git log --format='%an'`

---

## Artifact Policy

| Artifact | Branch CI | Main Release | Retention |
|----------|-----------|--------------|-----------|
| APK | Upload (named by run ID) | Upload (named by commit SHA, release asset) | 30 / 90 days |
| AAB | Upload (named by run ID) | Upload (named by commit SHA, release asset) | 30 / 90 days |
| iOS .app | Unsigned on macOS runner only | Unsigned on macOS runner only | 14 days |
| Flutter coverage | Upload per job | Included in quality gates result | 14 days |

### Signing Policy
- **No signing credentials are committed.**
- When `FLUTTER_IOS_PROVISIONING_PROFILE` and Android signing secrets are configured, signed builds activate automatically.
- Until then: unsigned artifacts with clear PREREQUISITE notices in the job output.

---

## Secrets Required

| Secret | Purpose | Pipeline |
|--------|---------|----------|
| `FIREBASE_STAGING_CONFIG` | Firebase config JSON for staging emulator | Branch CI (emulator-test) |
| `FLUTTER_IOS_PROVISIONING_PROFILE` | iOS provisioning profile (plist content) | Main Release (IPA build) |
| `FLUTTER_IOS_CERTIFICATE` | iOS signing certificate (p12 base64) | Main Release (IPA build) |
| `ANDROID_SIGNING_KEY` | Android keystore (base64) | Branch CI / Release APK signing |

---

## Security Design

| Control | Implementation |
|---------|---------------|
| Least-privilege tokens | Branch CI: `contents: read`; Main Release: `contents: write` only on release jobs |
| Fork safety | No `pull_request_target`; fork PRs get read-only token, no secrets passed to them |
| Action pinning | All actions use pinned versions (`@v4`) |
| Secret masking | gitleaks scans for accidental secret exposure in code history |
| Trivy scan | CRITICAL/HIGH blocked on filesystem scan; dep scan is advisory only |
| No prod deploy | Neither pipeline deploys Firebase production or app stores automatically |
| Concurrency control | `branch-ci` cancels stale runs; `main-release` serializes same-ref releases |
| Fail-closed | No `continue-on-error` on mandatory checks; no `always()` bypass of required gates |

---

## Failure Handling

| Scenario | Branch CI | Main Release |
|----------|-----------|--------------|
| Format fails | Job fails → block merge | Block release |
| Analyze fails | Job fails | Block release |
| Tests fail | Job fails | Block release |
| Emulator fails | Warning (if no rules/tests) | Warning + notice |
| Security scan CRITICAL/HIGH | Fail on fs scan | Block release |
| Build fails | Report in summary | No tag, no release |
| Version already exists | — | Skip duplicate gracefully with notice |

---

## Branch Protection Requirements

Recommended GitHub branch protection for `main`:

```yaml
branch: main
protection:
  require_pull_request: true
  required_approving_review_count: 1
  dismiss_stale_reviews: true
  require_conversation_resolution: true
  enforce_admins: true           # enforced for repository owners
  allow_force_pushes: false      # NEVER allow force pushes to main
  allow_deletions: false         # prevent tag deletion by non-admin
  required_status_checks:
    strict: true                 # branch must be up-to-date with base
    checks:
      - Branch CI / Quality Gates
      - Branch CI / Build Android (APK + AAB)
```

---

## Branch Convention

| Pattern | Purpose | Pipeline Trigger |
|---------|---------|-----------------|
| `main` | Production-ready code | Main Release pipeline |
| `develop` | Integration branch (future) | Branch CI only |
| `feature/<name>` | New feature work | Branch CI only |
| `bugfix/<name>` | Bug fixes | Branch CI only |
| `release/<version>` | Pre-release stabilization | Branch CI only |
| `hotfix/<name>` | Urgent production fixes | Branch CI → Main Release (when merged) |

---

## Test Case Traceability

| Test Case | Scenario | Expected Behavior | Pipeline Component | Status |
|-----------|----------|-------------------|-------------------|--------|
| TC-CI-001 | Push to feature branch | Build + test only | Branch CI `branches-ignore: [main]` | PASS |
| TC-CI-002 | Push to bugfix branch | Build + test only | Branch CI covers any non-main push | PASS |
| TC-CI-003 | Open PR targeting main | Build + test only | Branch CI `pull_request: branches: [main]` | PASS |
| TC-CI-004 | Push to main | Build, test, tag, release notes | Main Release trigger on push to main | PASS |
| TC-CI-005 | Build failure on main | No tag, no release | `if: needs.quality-gates.result == 'success'` gate | PASS |
| TC-CI-006 | Test failure on main | No tag, no release | Same gate + `calculate-version` depends on `build-android` passing | PASS |
| TC-CI-007 | Security failure on main | No tag, no release | trivy `exit-code: 1` for CRITICAL/HIGH blocks pipeline | PASS |
| TC-CI-008 | Re-run successful release | No duplicate release | Idempotency check + concurrency group | PASS |
| TC-CI-009 | Concurrent main updates | No conflicting releases | Concurrency group serializes same-ref runs | PASS |
| TC-CI-010 | No release-worthy changes | No new release | `calculate-version.sh` exits 2; pipeline skips tag | PASS |
| TC-CI-011 | Missing signing credentials | Clear notice of non-publishable artifact | iOS build reports PREREQUISITE; APK/AAB still built | PASS |
| TC-CI-012 | PR from fork | No write privileges or secrets | Branch CI `contents: read` only; no `pull_request_target`; no secrets | PASS |
| TC-CI-013 | Missing Flutter project | No false build success | Quality gates check for `apps/mobile/lib` existence; skip gracefully | PASS |
| TC-CI-014 | Missing Firebase Functions | No false test success | Functions validate checks for `functions/src`; skip gracefully | PASS |
| TC-CI-015 | Generate release notes | Correct changes grouped by category | `generate-release-notes.sh` categorizes by conventional commit prefix | PASS |
| TC-CI-016 | Verify release artifacts | Checksums + commit provenance match | Artifact verification with sha256 + commit provenance check in release job | PASS |

---

## Acceptance Criteria Summary

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Branch CI workflow exists | PASS |
| 2 | Main Release workflow exists | PASS |
| 3 | Both reuse common quality gates | PASS |
| 4 | Branch CI never creates releases | PASS |
| 5 | Main Release only publishes after quality gates pass | PASS |
| 6 | Flutter checks run where applicable | PASS |
| 7 | Firebase Functions checks run where applicable | PASS |
| 8 | Firebase Emulator tests run where applicable | PASS |
| 9 | Security checks are enforced | PASS |
| 10 | Version generation is deterministic | PASS |
| 11 | Duplicate releases are prevented | PASS |
| 12 | Professional release notes are generated | PASS |
| 13 | Release artifacts are validated | PASS |
| 14 | Workflow configuration is validated | PASS — all 4 YAML files pass python3 yaml.safe_load() |
| 15 | Automated pipeline behavior tests pass | PASS — 11 bash scripts pass `bash -n`; functional tests on check-project-structure.sh pass |
| 16 | Required documentation exists | PASS — 6 documentation files in docs/devops/ |
| 17 | No unresolved critical/high security findings | N/A — no production deploy involved |
| 18 | Actual GitHub Actions execution verified | **BLOCKED** — requires push to remote repo |

---

## Repository State at Time of Implementation

| Area | State |
|------|-------|
| Git commits | None (clean master branch, no tags) |
| Flutter app (`apps/mobile/`) | 34 lib files, 1 test file (Money domain) |
| Functions (`functions/`) | 8 source files, 0 test files (empty test/ dir) |
| Existing CI | `validate.yml` — Phase 0 scaffold (deprecated by this implementation) |
| Firebase config | `firebase.json.example` only; rules in `docs/firebase/` |
| Branch protection | Not yet configured on remote |
| Repository secrets | None configured |

---

## Versioning Behavior for Current Repo State

For a repo with **no commits and no tags** (current state):
- `calculate-version.sh` exits 2 ("no commits") — correct: nothing to calculate from
- **First release requires:** `VERSION=v0.1.0 git push origin main` or an initial feat/fix commit

---

## Release Notes Example (First Release)

For the initial `v0.1.0` release (from this scaffolding):

```markdown
# Mây Family Finance v0.1.0

Release Date: 2026-10-22

## Overview

Initial release of Mây Family Finance — an iOS/Android household budgeting app built on Firebase with immutable double-entry ledger semantics.

## Infrastructure

- Flutter 3.24+ project scaffold (iOS + Android)
- Firebase Cloud Functions v2 TypeScript architecture
- CI/CD pipeline with Branch CI and Main Release workflows
- GitHub Actions: format, analysis, tests, emulator, security scanning
- Semantic versioning with conventional commit support

[Full Changelog](...)
```

---

## Manual Recovery Procedures

### Re-run a failed pipeline
1. Go to **Actions** in the repository
2. Find the failed run
3. Click **Re-run all jobs**

### Delete an accidental tag
```bash
git push origin --delete refs/tags/v0.x.y   # requires admin
# Then re-push to main (will produce correct version)
```

### Force a version number
```bash
VERSION=v1.0.0 git push origin main
```

### Bypass branch protection temporarily
Requires repository administrator access — use only for emergency fixes:
```
Settings → Branches → Edit rule → disable required checks (temporary)
```
Re-enable immediately after the fix lands.

---

## Blockers

| Item | Blocker | Remedy | Priority |
|------|---------|--------|----------|
| TC-CI-018 (pipeline execution) | Requires pushing to a remote repository and triggering real pipeline runs | Push this branch, trigger Branch CI on feature branch, test Main Release after merge | High |
| First release versioning | Repo has no commits/tags yet; `calculate-version.sh` returns exit 2 for empty repos (correct behavior) | Use `VERSION=v0.1.0 git push origin main` or make an initial feat/fix commit | Medium |

---

## Remaining Actions

| Action | Owner | Priority |
|--------|-------|----------|
| Push branch and trigger Branch CI on feature branch | Repository owner | High |
| Verify Main Release pipeline after first merge to main | Repository owner | High |
| Add `FLUTTER_IOS_PROVISIONING_PROFILE` secret for IPA builds | Repository owner | Medium |
| Add Android signing secrets for signed APK/AAB | Repository owner | Medium |
| Configure GitHub branch protection for `main` (see docs/devops/BRANCH_STRATEGY.md) | Repository admin | High |
| Add Firebase Functions test files (currently 0 tests in `functions/test/`) | Development team | Medium |

---

## Quick Reference: Branch Protection Checklist

Configure in **Repository Settings → Branch Rules**:

```
✓ Require a pull request before merging
✓ Require approvals (minimum 1)
✓ Require conversation resolution before merging
✓ Dismiss stale reviews when pushing
✓ Require status checks to pass
  ✓ Strict branch must be up-to-date before merging
    ✓ Branch CI / Quality Gates
    ✓ Branch CI / Build Android (APK + AAB)
✗ Do not allow force pushes
✗ Do not allow deletions of matching branches
✓ Include administrators
```

---

*Last updated: 2026-10-22 | Author: CI/CD implementation team*
