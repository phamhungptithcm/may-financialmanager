# Mây Family Finance — CI/CD Architecture

## Overview

Mây Family Finance uses exactly **two logical CI/CD pipelines**:

| Pipeline | Trigger | Purpose |
|----------|---------|---------|
| **Branch CI** | Push to any non-main branch OR PR targeting main | Build, test, security scan — provide merge safety feedback |
| **Main Release** | Push to `main` | Run quality gates -> build release artifacts -> tag -> publish GitHub Release |

Both pipelines share a **common quality gates layer** implemented as a reusable workflow (`reusable-quality-gates.yml`). This ensures identical standards and prevents drift.

## Pipeline Architecture

```
                    +-------------------------+
                    |   Branch CI           |
                    |  (non-main / PR)      |
                    +----------+------------+
                               |
              +----------------+----------------+
              v                                 v
      +---------------+                +--------------+
      | Build APK+AAB |                |  Summary     |
      +---------------+                +--------------+


                    +-------------------------+
                    |   Main Release          |
                    |    (push -> main)       |
                    +----------+--------------+
                               |
              +----------------+----------------+
              v                                 v
     +--------------------+            +--------------+
     | Quality Gates      |---- PASS ->| Build Android|
     | (reusable)         |            | Build iOS    |
     +--------+-----------+            +------+-------+
              |                                |
         FAIL v                                v
    Release blocked            +-------------------+
                              | Version & Tag     |
                              | Release Notes     |
                              | GitHub Release    |
                              +-------------------+
```

## Reusable Quality Gates

File: `.github/workflows/reusable-quality-gates.yml`

Runs four parallel/ordered job groups:

| Job | Description | Gate Policy |
|-----|-------------|-------------|
| `flutter-validate` | Format (120) + analyze + unit tests (+ coverage) | **FAIL** blocks everything |
| `functions-validate` | TypeScript tsc --noEmit + ESLint + vitest + build | **FAIL** blocks everything |
| `emulator-test` | Firebase Emulator integration test (functions+database) | WARN on missing rules/tests |
| `security-scan` | gitleaks (secrets) + trivy (CRITICAL/HIGH fs + dep scan) | **FAIL** on CRITICAL/HIGH fs scan |

## Branch Protection Requirements

Recommended GitHub branch protection for `main`:

```yaml
branch: main
protection:
  require_pull_request: true
  required_approving_review_count: 1
  dismiss_stale_reviews: true
  require_conversation_resolution: true
  enforce_admins: true
  allow_force_pushes: false
  allow_deletions: false
  required_status_checks:
    strict: true
    checks:
      - Branch CI / Quality Gates
      - Branch CI / Build Android (APK + AAB)
```

## Versioning Policy

Semantic versioning: `vMAJOR.MINOR.PATCH`

| Commit Type | Bump | Example |
|-------------|------|---------|
| `feat:` / `feat(scope):` | MINOR (pre-1.0) or MAJOR (at 1.0+) | v0.2.0 |
| `fix:` / `fix(scope):` | PATCH | v0.1.1 |
| `!:` suffix or `BREAKING CHANGE:` | MAJOR | v1.0.0 |
| `docs:`, `test:`, `chore:`, `refactor:` | (no release if only these) | -- |

**Initial version:** `v0.1.0` (for first release from clean repo).

**Pre-1.0 policy:** MAJOR = breaking API changes; MINOR = new features; PATCH = bug fixes.

Version calculation uses conventional commit prefixes in the diff range (last tag -> HEAD). If no release-worthy change detected, the pipeline completes successfully without creating a tag or release.

## Release Notes Policy

Professional release notes are generated automatically for every main push that passes quality gates and has release-worthy changes. Structure:

1. **Overview** -- version header + date
2. **New Features** (`feat:` commits)
3. **Improvements** (`perf:`, general commits)
4. **Bug Fixes** (`fix:` commits)
5. **Security** (security-related commits, no vulnerability disclosure)
6. **Technical Changes** (`refactor:`, dependency updates)
7. **Breaking Changes** (! suffix / BREAKING CHANGE:)
8. **Merged Pull Requests** (PR numbers from merge commits)
9. **Full Changelog** link

Release notes are generated without AI APIs -- purely from git history metadata.

## Artifact Policy

| Artifact | Branch CI | Main Release | Retention |
|----------|-----------|--------------|-----------|
| APK | Upload | Upload (release name) | 30 / 90 days |
| AAB | Upload | Upload (release name) | 30 / 90 days |
| iOS .app | Unsigned (macOS only) | Unsigned (macOS only) | 14 days |
| Flutter coverage | Upload | Included in quality gates | 14 days |

**Signing:** No signing credentials are committed. When `FLUTTER_IOS_PROVISIONING_PROFILE` and Android signing secrets are configured, signed builds activate automatically. Until then: unsigned artifacts with clear PREREQUISITE notices.

## Secrets Required

| Secret | Purpose | Pipeline |
|--------|---------|----------|
| `FIREBASE_STAGING_CONFIG` | Firebase config JSON for staging emulator | Branch CI (emulator-test) |
| `FLUTTER_IOS_PROVISIONING_PROFILE` | iOS provisioning profile (plist) | Main Release (IPA build) |
| `FLUTTER_IOS_CERTIFICATE` | iOS signing certificate (p12 base64) | Main Release (IPA build) |
| `ANDROID_SIGNING_KEY` | Android keystore (base64) | Branch CI / Release APK signing |

## Security Design

| Control | Implementation |
|---------|---------------|
| Least-privilege tokens | Branch CI: `contents: read`; Release: `contents: write` only on release jobs |
| Fork safety | No `pull_request_target`; fork PRs get read-only token, no secrets |
| Action pinning | All actions use pinned versions (`@v4`) |
| Secret masking | gitleaks scans for accidental secret exposure |
| Trivy scan | CRITICAL/HIGH blocked on file system scan; dep scan is advisory only |
| No prod deploy | Neither pipeline deploys Firebase production or app stores |

## Failure Handling

| Scenario | Branch CI | Main Release |
|----------|-----------|--------------|
| Format fails | Job fails -> block merge | Block release |
| Analyze fails | Job fails | Block release |
| Tests fail | Job fails | Block release |
| Emulator fails | Warning (if no rules/tests) | Warning + notice |
| Security scan CRITICAL/HIGH | Fail on fs scan | Block release |
| Build fails | Report in summary | No tag, no release |
| Version exists | -- | Skip duplicate gracefully |

## Manual Recovery

If a pipeline is stuck or requires manual intervention:

1. **Stuck concurrency:** Go to Actions -> cancel the stuck run -> re-run after fix.
2. **Failed release (partial):** Fix the failing quality gate -> push to main -> re-run. No partial state persists.
3. **Delete accidental tag:** `git push origin --delete refs/tags/<TAG>` then re-push to main.
4. **Rollback a release:** GitHub Releases are immutable by design. Create a new revert commit and let the next release handle it.

---

*Last updated: 2026-10-22 | Author: CI/CD implementation team*
