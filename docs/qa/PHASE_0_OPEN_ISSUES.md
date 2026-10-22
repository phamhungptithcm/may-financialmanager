# Phase 0 Open Issues

**Audit date:** 2026-10-22  
**Auditor:** Claude Code (automated audit)

---

## Priority Classification

| Prefix | Severity | Definition |
|--------|----------|-----------|
| P0 | CRITICAL | Blocks any production deployment or fundamental security/data integrity |
| P1 | HIGH | Must be resolved before Phase 1 auth implementation |
| P2 | MEDIUM | Should be addressed before financial feature implementation |
| P3 | LOW | Nice-to-have improvements; can defer to later phases |

---

## P0 — CRITICAL Issues (block production deployment)

| ID | Title | Category | Source | File(s) | Status | Resolution |
|----|-------|----------|--------|---------|--------|------------|
| SEC-01 | `checkHouseholdAccess()` returns true unconditionally | Security | specs/08 RBAC | functions/src/core/authorization/household_auth.ts:31 | OPEN | Implement actual RTDB `/members/{hid}/{uid}` membership check with role retrieval. Replace `return true` with Admin SDK lookup and role comparison. |
| FIN-01 | Idempotency fingerprint uses adler-like hash instead of SHA-256 | Financial Integrity | specs/03/Ledger, BR-14 | functions/src/core/idempotency/idempotency_service.ts:73-80 | OPEN | Replace custom `hash()` with Node.js `crypto.createHash('sha256')`. Same-deterministic-key requirement demands collision resistance. |
| SEC-02 | App Check validation is a no-op trust | Security | specs/08/NetworkIdentity | functions/src/core/auth/auth_context.ts:50-57 | OPEN | Verify App Check token via Firebase Admin SDK `appCheck().verify()`. Return error on invalid/expired tokens. |

## P1 — HIGH Issues (block Phase 1 auth)

| ID | Title | Category | Source | File(s) | Status | Resolution |
|----|-------|----------|--------|---------|--------|------------|
| DEV-01 | No callable function handlers implemented | Development | specs/05/Functions Catalog, Milestone 1 | index.ts imports from `./modules/*` (non-existent) | DOCUMENTED | All module handlers (createHousehold, inviteMember, createLedgerEvent, etc.) are Phase 1 scope. Not a defect but must be tracked. |
| DEV-02 | No Firebase Emulator integration tests | Testing | specs/10/Acceptance scenarios | functions/test/ (empty) | DOCUMENTED | TC-001 through TC-043 (60 test cases per specs) must be written. First priority: TC-001 (first sign-in household), TC-035 (cross-tenant isolation). |
| SEC-03 | RTDB query-bounded read rules may not work correctly | Security | specs/03/Consistency, database.rules.json:118 | docs/firebase/database.rules.json:118,132 | OPEN | `query.orderByChild` and `query.limitToLast` are path variables in `.read`, not query parameters. Correct to remove the query comparison from `.read`. |
| AUTH-01 | Missing 4 foundation UI components (A04, A06, A13, A24) | UI | specs/09 Component Library | mayIconButton, maySectionHeader, mayDateField, maySwipeAction NOT present | OPEN | Implement before Phase 1 screen implementation. These are required by Home, Transaction List, and other screens. |
| CI-01 | CI quality gate lacks explicit per-job permissions | Security (CI) | specs/11/CI/CD governance | .github/workflows/reusable-quality-gates.yml | OPEN | Add explicit `permissions:` blocks to each job in reusable workflow to prevent permission inheritance from caller. |

## P2 — MEDIUM Issues

| ID | Title | Category | Source | File(s) | Status | Resolution |
|----|-------|----------|--------|---------|--------|------------|
| FIN-02 | `fromMajor(double)` constructor allows float precision loss | Financial Integrity | money.dart:33-40 | apps/mobile/lib/core/domain/money.dart:33 | OPEN | Accept `String` or `int` instead of `double`. Parse internally to avoid double-to-int conversion imprecision for large amounts. |
| SEC-04 | Error sanitization missing amount pattern | Security (PII) | specs/08/Privacy | functions/src/core/errors/app_error.ts:84-98 | OPEN | Add `\d{1,3}(?:,\d{3})+(?= VND\| USD\|\b)` regex to redact financial amounts in error messages. |
| SEC-05 | CI permission inheritance — all quality gate jobs get `contents: write` when run from main-release | Security (CI) | main-release.yml:29-31 | .github/workflows/reusable-quality-gates.yml | OPEN | Add per-job permissions; gitleaks/trivy only need `contents: read`. |
| UI-01 | MaySegmentedControl missing VoiceOver labels | Accessibility | specs/09 A15 | apps/mobile/lib/shared/widgets/may_segmented_control.dart:43 | PARTIAL | Add Semantics widgets with accessibility labels per spec requirement. |
| UI-02 | MayToast/Snackbar missing semantic announcement | Accessibility | specs/09 A22 | apps/mobile/lib/shared/widgets/may_snackbar.dart:38 | PARTIAL | Add Semantics widget with label for screen reader announcement. |
| DEV-03 | Period key ignores timezone parameter | Domain Logic | specs/01 BR-06 | apps/mobile/lib/core/domain/period.dart:21-32 | OPEN | `tz` parameter accepted in signatures but not applied to computation. Use `DateTime.fromMicrosecondsSinceEpoch(ms, zone: tz)`. |
| DEV-04 | Localization uses manual mapping instead of ARB files | i18n | specs/09 localization | apps/mobile/lib/core/localization/app_localizations.dart | PARTIAL | Generate from .arb files for proper Flutter localization support. Manual mapping works but is not the standard pattern. |
| CI-02 | Emulator test exit code 1 ambiguous (crash vs no-tests) | CI/CD | branch-ci.yml:160-163 | .github/workflows/reusable-quality-gates.yml:156-159 | DOCUMENTED | When emulator actually runs, distinguish crash from "no tests" by checking stderr output. |

## P3 — LOW Issues (nice-to-have)

| ID | Title | Category | Source | File(s) | Status | Resolution |
|----|-------|----------|--------|---------|--------|------------|
| DEV-05 | `.claude/rules/common-vs-feature.md` referenced in CLAUDE.md but doesn't exist | Documentation | CLAUDE.md references common-vs-feature.md | .claude/rules/common-vs-feature.md missing | OPEN | Create the file per spec architecture policy. |
| CI-03 | pub.dev retry logic inconsistent between workflows | CI/CD | branch-ci.yml has retry, reusable-quality-gates doesn't | .github/workflows/branch-ci.yml:75-82 | DOCUMENTED | Standardize retry logic in reusable workflow or both callers. |
| CI-04 | Release notes fallback minimal on fresh repos | CI/CD | generate-release-notes.sh may produce empty output | scripts/ci/generate-release-notes.sh | LOW | Improve fallback to include commit count, changed files summary. |
| DEV-06 | Unprotected git tag push in release workflow | Security (CI) | Tag pushed without branch protection rule | main-release.yml:242-250 | LOW | Add protected branch rule requiring signed tags for main. |
| DEV-07 | No Secret Manager integration for dev/staging/prod configs | DevOps | specs/11 infrastructure management | infra/, docs/firebase/firebase.json.example | DOCUMENTED | Expected for scaffold; implement before staging deployment. |

---

## Summary by Category

| Category | P0 | P1 | P2 | P3 | Total |
|----------|----|----|----|----|-------|
| Security | 2 | 1 | 2 | 1 | 6 |
| Financial Integrity | 1 | 0 | 1 | 0 | 2 |
| Development | 0 | 2 | 2 | 1 | 5 |
| UI/Accessibility | 0 | 1 | 2 | 0 | 3 |
| CI/CD | 0 | 1 | 1 | 2 | 4 |
| **Total** | **3** | **5** | **8** | **4** | **20** |

---

## Blocked Items (Cannot be addressed until runtime available)

| ID | Item | Reason | When Unblocked |
|----|------|--------|---------------|
| BLK-01 | Flutter SDK installed & `flutter analyze`/`flutter test` run | No Flutter SDK on audit machine | Install Flutter 3.24+ |
| BLK-02 | TypeScript compile (`tsc --noEmit`) executed | Security classifier blocked bash execution | Allow automated code execution or run manually |
| BLK-03 | Firebase Emulator integration test execution | No Firebase project configured locally | `firebase emulators:start` with test fixtures |
| BLK-04 | iOS build validation (macOS not available) | Linux runner, no Xcode toolchain | Run on macOS runner (already in CI config) |
| BLK-05 | Visual screenshot comparison (HTML prototype vs Flutter) | No Flutter runtime + no browser automation | Set up Puppeteer/Playwright for HTML rendering + Flutter golden tests |
| BLK-06 | Dark mode color contrast AA verification | No measurement tool available | Use Flutter Contrast CLI or manual calculation against WCAG AA (4.5:1 for normal text) |

---

## Defect Remediation Status

### Defects already addressed in current codebase:
- None found during this audit — no prior defects were fixed as part of Phase 0.

### Defects identified and pending remediation:
| # | Defect | Severity | Attempted Fixes | Current Status |
|---|--------|----------|-----------------|---------------|
| 1 | household_auth placeholder (SEC-01) | CRITICAL | N/A — requires full auth implementation | OPEN |
| 2 | Idempotency hash (FIN-01) | HIGH | N/A — requires crypto import | OPEN |
| 3 | App Check no-op (SEC-02) | HIGH | N/A — requires Firebase Admin SDK verification | OPEN |
| 4 | Period timezone ignored (DEV-03) | MEDIUM | N/A | OPEN |
| 5 | Error sanitization gap (SEC-04) | MEDIUM | N/A — regex pattern to add | OPEN |

---

**Total open issues: 20 (3 P0, 5 P1, 8 P2, 4 P3)**  
**P0 must be resolved before Phase 1 auth production deployment.**
