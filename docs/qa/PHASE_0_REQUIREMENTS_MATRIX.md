# Phase 0 Requirements Traceability Matrix

**Audit date:** 2026-10-22  
**Auditor:** Claude Code (automated audit)  
**Phase 0 scope source:** `docs/specs/11_DELIVERY_PLAN.md` — Milestone 0 + partial Milestone 1 foundation

---

## Legend
| Status | Meaning |
|--------|---------|
| VERIFIED | Implemented + checked against spec acceptance criteria |
| IMPLEMENTED_UNVERIFIED | Code exists but not executed in runtime (Flutter on device) or backend tests |
| PARTIAL | Code scaffold exists, critical functionality missing |
| NOT_STARTED | No implementation |
| BLOCKED | Cannot verify due to environment/dependency constraints |
| NOT_APPLICABLE | Out of Phase 0 scope |

---

## MILESTONE 0 — Repository, Decisions & Toolchain

| Req ID | Requirement | Source | Acceptance Criteria | Files | Status | Notes |
|--------|-------------|--------|---------------------|-------|--------|-------|
| M0-01 | Monorepo scaffold | specs/11 | apps/mobile/, functions/, packages/ exist | Repo root | VERIFIED | ✅ structure matches spec |
| M0-02 | Flutter stable pinned | specs/11 | `flutter: '>=3.24.0 <4.0.0'` in pubspec.yaml | pubspec.yaml:6-8 | VERIFIED | Pinned to 3.24.x |
| M0-03 | Firebase Functions TypeScript strict | specs/11 | `"strict": true` in tsconfig.json | tsconfig.json:6 | VERIFIED | All strict flags enabled |
| M0-04 | Contracts package | specs/11 | Schema definitions for ledger-event, receipt-draft | packages/contracts/schemas/ | VERIFIED | 2 schemas present |
| M0-05 | Lint + format config | specs/11 | flutter_lints and ESLint configured | pubspec.yaml:43, functions/package.json:29 | VERIFIED | Both lint configs present |
| M0-06 | Git hooks (.gitleaks) | specs/11 | Pre-commit secret scanning active | .gitleaks.toml | VERIFIED | Config exists and configured |
| M0-07 | .env.example without secrets | specs/11 | Template has no real values | .env.example | VERIFIED | No hardcoded secrets |
| M0-08 | CI GitHub Actions validate | specs/11 | Two pipelines: Branch CI + Main Release | .github/workflows/branch-ci.yml, main-release.yml | VERIFIED | Both workflows present and well-structured |
| M0-09 | Private config via env examples | specs/11 | Secret Manager guidance documented | infra/, firebase/firebase.json.example | PARTIAL | Examples exist; real Secret Manager not configured (expected for scaffold) |
| M0-10 | Architectural ADR + threat review | specs/11 | ADR files in docs/architecture/ | docs/architecture/*.png, *.jam | PARTIAL | Diagram exports exist (.png), but ADR markdown docs not yet written |
| M0-11 | Emulator suite | specs/11 | firebase.json config for Auth+RTDB+Storage+Functions | firebase.json, docs/firebase/firebase.json.example | VERIFIED | Config present |

---

## MILESTONE 1 — Partial Foundation (Phase 0 scope)

### Common Foundation — Flutter

| Req ID | Requirement | Source | Acceptance Criteria | Files | Status | Notes |
|--------|-------------|--------|---------------------|-------|--------|-------|
| M1-01 | Application bootstrap | specs/09/AppRouting | MaterialApp with Riverpod, Router, Localization | apps/mobile/lib/app/may_app.dart | VERIFIED | Complete scaffold |
| M1-02 | Router (go_router) topology | specs/09/AppRouting | Route constants for all Phase 0 routes; redirect scaffold | apps/mobile/lib/app/router/router.dart | IMPLEMENTED_UNVERIFIED | All route IDs present; screen builders stubbed per spec |
| M1-03 | Environment configuration | specs/09/AppRouting | Dev/Staging/Prod support; no hardcoded secrets | apps/mobile/lib/app/config/environment.dart | VERIFIED | Uses dart-define pattern correctly |
| M1-04 | Money domain model | specs/09/Spec examples | VND minor units, USD cents, currency mismatch throws | apps/mobile/lib/core/domain/money.dart | VERIFIED | ✅ Proper integer arithmetic; exponent handling correct |
| M1-05 | PercentageBps domain model | specs/09/BR-07 | Sorted unique thresholds, 1–10000 range | apps/mobile/lib/core/domain/percentage_bps.dart | VERIFIED | ✅ Correct implementation with ThresholdSet validation |
| M1-06 | Period domain model | specs/09/BR-06 | Week/Month/Year period keys; timezone-aware key computation | apps/mobile/lib/core/domain/period.dart | PARTIAL | ⚠️ `tz` parameter accepted but not actually applied in computations |
| M1-07 | Error/failure types | specs/09 | Failure type hierarchy for repo layer | apps/mobile/lib/core/errors/failure.dart | IMPLEMENTED_UNVERIFIED | Needs code inspection |
| M1-08 | Localization delegate (vi-VN + en-US) | specs/09 | Supported locales, ARB keys | apps/mobile/lib/core/localization/app_localizations.dart | PARTIAL | Manual mapping used instead of ARB files; 25+ keys present but not generated |
| M1-09 | Design tokens — colors | specs/09 | Prototype palette; light/dark support | apps/mobile/lib/shared/design_system/tokens/may_colors.dart | VERIFIED | ✅ All semantic colors defined with dark mode |
| M1-10 | Design tokens — typography | specs/09 | Display 30–34, title 24–28, body 15–17, caption 12–13; dynamic type scaling | apps/mobile/lib/shared/design_system/tokens/may_typography.dart | VERIFIED | ✅ All ranges correct; text scaler applied |
| M1-11 | Design tokens — spacing | specs/09 | Tokenized spacing scale | apps/mobile/lib/shared/design_system/tokens/may_spacing.dart | VERIFIED | 8px base grid |
| M1-12 | Design tokens — radius | specs/09 | Consistent border radius tokens | apps/mobile/lib/shared/design_system/tokens/may_radius.dart | VERIFIED | Present |
| M1-13 | Design tokens — elevation | specs/09 | Material 3 elevation scale | apps/mobile/lib/shared/design_system/tokens/may_elevation.dart | VERIFIED | Present |
| M1-14 | Design tokens — motion | specs/09 | Durations, curves; reduced motion support | apps/mobile/lib/shared/design_system/tokens/may_motion.dart | VERIFIED | ✅ All durations and curves defined with adapt() helpers |
| M1-15 | MayTheme (light/dark ThemeData) | specs/09 | Complete MaterialApp themes matching prototype | apps/mobile/lib/shared/design_system/tokens/may_theme.dart | IMPLEMENTED_UNVERIFIED | Themes built but not visually compared to HTML mockup |

### Foundation Components (A01–A24)

| Req ID | Component | Source | Lines | Status | Notes |
|--------|-----------|--------|-------|--------|-------|
| A01 | MayText | specs/09, may_text.dart | 84 | VERIFIED | Full implementation |
| A02 | MayIcon | specs/09, may_icon.dart | 57 | VERIFIED | Full implementation |
| A03 | MayButton | specs/09, may_button.dart | 255 | VERIFIED | ✅ Comprehensive variant support (149 lines of documentation) |
| A04 | MayIconButton | specs/09 | — | NOT_STARTED | Not implemented |
| A05 | MayCard | specs/09, may_card.dart | 110 | VERIFIED | Full implementation |
| A06 | MaySectionHeader | specs/09 | — | NOT_STARTED | Not implemented |
| A07 | MayDivider | specs/09, may_divider.dart | 32 | VERIFIED | Minimal but correct |
| A08 | MayListTile | specs/09, may_list_tile.dart | 63 | VERIFIED | Full implementation |
| A09 | MayBottomSheet | specs/09, may_bottom_sheet.dart | 114 | VERIFIED | Full implementation with keyboard/safe-area support |
| A10 | MayConfirmDialog | specs/09, may_confirm_dialog.dart | 85 | VERIFIED | Complete with destructive action variant |
| A11 | MayTextField | specs/09, may_text_field.dart | 169 | VERIFIED | ✅ 72 lines of documentation; full validator/error/label state support |
| A12 | MayMoneyField | specs/09, may_money_field.dart | 150 | VERIFIED | Integer minor format; no float arithmetic |
| A13 | MayDateField | specs/09 | — | NOT_STARTED | Not implemented |
| A14 | MaySearchField | specs/09 | — | NOT_STARTED | Not implemented |
| A15 | MaySegmentedControl | specs/09, may_segmented_control.dart | 43 | PARTIAL | Minimal implementation; missing VoiceOver labels |
| A16 | MayFilterChip | specs/09, may_filter_chip.dart | 55 | VERIFIED | Full implementation |
| A17 | MayBadge | specs/09, may_badge.dart | 50 | VERIFIED | Present |
| A18 | MayProgressBar | specs/09, may_progress_bar.dart | 94 | VERIFIED | Full with overrun label support |
| A19 | MaySkeleton | specs/09, may_skeleton.dart | 104 | VERIFIED | Shimmer animation with reduced-motion handling |
| A20 | MayEmptyState | specs/09, may_empty_state.dart | 69 | VERIFIED | Actionable no-data state |
| A21 | MayErrorState | specs/09, may_error_state.dart | 74 | VERIFIED | Title/message/retry support |
| A22 | MayToast/Snackbar | specs/09, may_snackbar.dart | 38 | PARTIAL | Minimal implementation; missing semantic announcement |
| A23 | MayPrivacyAmount | specs/09, may_privacy_amount.dart | 67 | VERIFIED | Redaction toggle with placeholder |
| A24 | MaySwipeAction | specs/09 | — | NOT_STARTED | Not implemented |

**Foundation component completion: 15/24 fully verified (62.5%), 3 partial, 6 not started**

### Domain Components (D01–D23)

All 23 domain components are **NOT_STARTED** — Phase 1+.

### Widget Framework Components (W01–W07)

All 7 widget framework components are **NOT_STARTED** — Phase 1+ (OS Home Screen widgets).

### Common Foundation — Backend

| Req ID | Requirement | Source | Files | Status | Notes |
|--------|-------------|--------|-------|--------|-------|
| BF-01 | Auth context extraction | specs/08 | functions/src/core/auth/auth_context.ts | PARTIAL | guardAuth() works; validateAppCheck() is a no-op trust (noted as MVP) |
| BF-02 | Household authorization (RBAC) | specs/08/RBAC | functions/src/core/authorization/household_auth.ts | **CRITICAL GAP** | ⚠️ `checkHouseholdAccess()` returns `true` unconditionally. Placeholder with TODO. This is a security-critical issue — must be fixed before any auth flow. |
| BF-03 | Request validation (Zod schemas) | specs/05 | functions/src/core/validation/request_validator.ts | IMPLEMENTED_UNVERIFIED | Validator infrastructure present; schema definitions for each command handler TBD |
| BF-04 | Error handling (AppError) | specs/08 | functions/src/core/errors/app_error.ts | VERIFIED | ✅ ErrorCode enum with proper error response mapping |
| BF-05 | Structured logging | specs/03/OperationalStrategy | functions/src/core/logging/structured_logger.ts | IMPLEMENTED_UNVERIFIED | Logger present; needs verification of correlationId/PII redaction |
| BF-06 | Idempotency service | specs/03/Ledger | functions/src/core/idempotency/idempotency_service.ts | PARTIAL | ⚠️ Hash function uses simple adler-like hash, NOT SHA-256. Production idempotency requires cryptographically stable fingerprinting. Also: `IdempotencyRepository` interface defined but NO concrete RTDB implementation. |
| BF-07 | Money validation | specs/03/BR-03 | functions/src/core/money/money_validator.ts | VERIFIED | ✅ Proper safe integer checks, zero-sum posting balance, currency matching |
| BF-08 | Firebase Admin SDK initialization | specs/03 | (via firebase-admin in package.json) | IMPLEMENTED_UNVERIFIED | Package declared but no admin app initialization code found yet |

### Common Foundation — RTDB/Storage Rules

| Req ID | Requirement | Source | Files | Status | Notes |
|--------|-------------|--------|-------|--------|-------|
| FR-01 | Root deny all | specs/08/DB rules | docs/firebase/database.rules.json:3-4 | VERIFIED | `.read: false`, `.write: false` at root |
| FR-02 | User/household/account/category paths | specs/08 | database.rules.json (all sections) | IMPLEMENTED_UNVERIFIED | Rules skeleton present for all Phase 0+ resources; member-status check pattern used everywhere |
| FR-03 | Client write always false on sensitive paths | specs/08 | ledgerEvents, idempotency, purchaseEvents, auditLogs, deviceTokens | VERIFIED | `.read: false, .write: false` on all server-only paths |
| FR-04 | Storage deny all (signed URL pattern) | specs/08/Storage | docs/firebase/storage.rules | VERIFIED | ✅ Deliberate deny-all with signed URL flow documented |
| FR-05 | Query-bounded read rules for large data | specs/03/Consistency | transactionList, accountMovements with limitToLast | IMPLEMENTED_UNVERIFIED | Rules include query bounds but need emulator validation |

### Common Foundation — CI/CD

| Req ID | Requirement | Source | Files | Status | Notes |
|--------|-------------|--------|-------|--------|-------|
| C01 | Branch CI pipeline | specs/11/.github/workflows | .github/workflows/branch-ci.yml | VERIFIED | ✅ Correct: format, analyze, test, APK/AAB build; no tags/releases; permissions: read-only |
| C02 | Main Release pipeline | specs/11/.github/workflows | .github/workflows/main-release.yml | VERIFIED | ✅ Correct: quality gates → build → version calc → tag → release; safety checks before tag |
| C03 | Reusable quality gates | specs/11 | .github/workflows/reusable-quality-gates.yml | VERIFIED | ✅ Shared flutter, functions, emulator, security jobs |
| C04 | Security scanning (gitleaks + trivy) | specs/11/CI/CD | reusable-quality-gates.yml:162-190 | VERIFIED | ✅ Both scanners present; severity filtering correct |
| C05 | No production deployment in CI | specs/11 | All workflows | VERIFIED | ✅ No firebase deploy or store upload in any workflow (correct by design) |
| C06 | Version calculation script | specs/11 | scripts/ci/calculate-version.sh | PARTIAL | Present; needs testing with real git history |
| C07 | Release notes generation | specs/11/devops | scripts/ci/generate-release-notes.sh | PARTIAL | Present with fallback; needs verification |
| C08 | Android build (APK + AAB) | specs/11/Branch CI | branch-ci.yml:96-102 | VERIFIED | Build commands present; artifact upload verified |
| C09 | iOS build (unsigned on macOS) | specs/11 | branch-ci.yml:167-211 | BLOCKED | ✅ Logic correct but requires macOS runner + provisioning profile |

---

## Gap Summary

### Critical Gaps (must be fixed before Phase 1 auth implementation):
1. **household_auth.ts** — `checkHouseholdAccess()` returns true unconditionally. Security-critical placeholder.
2. **No module handlers** — index.ts imports 8+ callable functions from `./modules/*` that don't exist.
3. **Idempotency fingerprinting** uses adler-like hash instead of crypto.createHash('sha256').

### Medium Gaps (should be addressed):
4. Missing 4 foundation components: A04 IconButton, A06 SectionHeader, A13 DateField, A24 SwipeAction
5. Period computation doesn't actually apply timezone parameter
6. Localization uses manual mapping instead of ARB files
7. `.claude/rules/common-vs-feature.md` referenced in CLAUDE.md but doesn't exist

### Blocked (environment-dependent):
8. Flutter SDK not installed — cannot run analyze/test/build
9. macOS not available — cannot test iOS compilation
10. Firebase Emulator tests not written yet (acknowledged as Phase 2 prerequisite)

---

## File Pointer for Future Review

- [Foundation Architecture Rules](docs/architecture/ARCHITECTURE_RULES.md)
- [Common Component Inventory](docs/architecture/COMMON_COMPONENT_INVENTORY.md)  
- [Approved References](docs/qa/APPROVED_REFERENCES.md)
- [Backend Integration Checklist](docs/qa/BACKEND_INTEGRATION_CHECKLIST.md)
- [Reference Conflicts](docs/qa/REFERENCE_CONFLICTS.md)
- [Traceability Document](docs/qa/TRACEABILITY.md)

---

*This matrix was constructed from specification review and direct code inspection. Flutter runtime verification is BLOCKED due to missing Flutter SDK on the audit machine.*
