# Phase 0 Test Report

**Audit date:** 2026-10-22  
**Environment:** Linux (no Flutter SDK, no macOS, no Firebase emulator)  
**Auditor:** Claude Code (automated audit + code inspection)

---

## 1. Test Execution Summary

| Layer | Command / Method | Executed? | Result |
|-------|-----------------|-----------|--------|
| Dart format | `dart format --set-exit-code lib/ --line-length 120` | NO | NOT_EXECUTED (Flutter SDK not installed) |
| Dart analyze | `flutter analyze --no-fatal-infos` | NO | NOT_EXECUTED |
| Flutter unit tests | `flutter test --coverage --concurrency=4` | NO | NOT_EXECUTED |
| Flutter widget tests | Manual code inspection of 20 shared widgets | YES | PARTIAL (code review only) |
| Flutter integration tests | N/A (no feature screens implemented yet) | NO | NOT_STARTED |
| Backend TypeScript compile | `tsc --noEmit` | DENIED | Security classifier blocked automated code execution |
| Backend lint | `eslint src/ --ext .ts` | NO | NOT_EXECUTED |
| Backend unit tests | `npm test (vitest run)` | NO | NOT_EXECUTED |
| Firebase Emulator integration | `firebase emulators:exec --only functions,database "npm test"` | NO | NOT_EXECUTED (no test files exist yet) |
| Security scan (gitleaks) | `gitleaks/gitleaks-action@v2` in CI workflows | YES (scaffolded) | SEE CI/CD REPORT |
| Security scan (trivy fs/dep) | `aquasecurity/trivy-action@v0` in CI workflows | YES (scaffolded) | SEE CI/CD REPORT |
| E2E smoke test | Full happy/negative path simulation | NO | NOT_EXECUTED |

---

## 2. Unit Test Coverage

### Flutter — money_test.dart

Only one unit test file exists: `apps/mobile/test/core/domain/money_test.dart`

**What it covers:**
- Money value construction (minor + currency)
- Addition, subtraction, multiplication, division
- Comparison operators (>, <, >=, <=)
- Formatting (VND and USD)
- JSON serialization/deserialization
- Zero/positive/negative accessors

**Estimated lines covered:** ~30–50 lines of the 216-line Money class (~15–23%)

### Flutter — Missing unit tests

| Component | Lines | Tests Needed | Status |
|-----------|-------|-------------|--------|
| PercentageBps (121 lines) | ✅ Full implementation | ThresholdSet validation, ratio/boundary tests | NOT_STARTED |
| Period/ MonthPeriod (91 lines) | ✅ Full implementation | Period key computation, timezone edge cases | NOT_STARTED |
| AppFailureCode/Result (143 lines) | ✅ Full implementation | Success/Error mapping, mapFailure, orThrow | NOT_STARTED |
| AppLocalizations (138 lines) | ✅ Manual mapping | vi-VN vs en-US key parity test | NOT_STARTED |
| All 20 shared widgets | ~1,639 total | Widget build tests with light/dark/200% font | NOT_STARTED |

### Backend — unit tests

**Test files found:** None in `functions/test/` (directory is empty).

The `vitest` framework is configured and `npm test` is wired as a script, but:
- No test files exist
- No test fixtures for Firebase Emulator
- No mock setup for RTDB/Storage rules testing

**Backend infrastructure code NOT tested by unit tests:**
| File | Lines | Coverage | Risk |
|------|-------|----------|------|
| app_error.ts | 99 | 0% | Medium — error codes manually verified |
| structured_logger.ts | 111 | 0% | HIGH — PII redaction critical, untested |
| money_validator.ts | 89 | 0% | CRITICAL — financial integrity, untested |
| auth_context.ts | 58 | 0% | CRITICAL — authentication, untested |
| household_auth.ts | 82 | 0% | CRITICAL — authorization placeholder, untested |
| idempotency_service.ts | 81 | 0% | CRITICAL — duplicate prevention, untested |

---

## 3. Financial Integrity Verification (Code Inspection)

### Money Domain Model (`apps/mobile/lib/core/domain/money.dart`)

**VERIFIED ✅ Invariants:**
- VND exponent = 0 (whole numbers), USD exponent = 2 (cents) — matches spec BR-03
- Currency mismatch throws `ArgumentError` in all arithmetic methods
- No `double` used for financial storage; `major` accessor returns double only for display
- `fromMajor(double)` and `parseFormatted()` handle finite validation
- JSON serialization uses minor + currency (round-trip safe)
- `hashCode` includes both minor and currency (correct equality semantics)

**NOTES ⚠️:**
- `fromMajor(double majorAmount, String currency)` accepts a `double` parameter. While the factory validates finiteness, it would be safer to accept `String` or `int` and parse internally per spec invariants. Currently: minor precision loss possible for very large amounts.

### Backend Money Validator (`functions/src/core/money/money_validator.ts`)

**VERIFIED ✅:**
- `validateMoneyAmount()` correctly checks safe integer, positive requirement for EXPENSE/INCOME
- `validatePostingBalance()` enforces zero-sum invariant across deltas
- `validatePostingsCurrency()` ensures all postings share the same currency
- `normalizeTransfer()` validates equal magnitude, produces correct signed deltas
- `validateLedgerAccount()` validates TYPE:id format

### PercentageBps (`apps/mobile/lib/core/domain/percentage_bps.dart`)

**VERIFIED ✅:**
- Range: 1–10000 bps (0.01%–100%) enforced via constructor
- ThresholdSet validates sorted, unique thresholds
- `ofAmount()` uses ratio multiplication (int result) — no float intermediate
- `firstCrossed()` correctly finds first exceeded threshold

---

## 4. Code Quality Assessment (Static Inspection)

### Flutter Code Quality

| Metric | Score | Notes |
|--------|-------|-------|
| Immutable value objects | ✅ | Money, PercentageBps, MonthPeriod all use `@immutable` |
| Sealed Result type | ✅ | Error<F> / Success<T, F> pattern prevents silent failures |
| AppFailureCode enum | ✅ | 12 stable error codes matching backend ErrorCode |
| Correlation ID in Failure | ✅ | Present in both Flutter and TypeScript |
| PII redaction in logger | ✅ | SENSITIVE_FIELDS list covers amountMinor, OCR tokens, billing signatures |
| Text scaler support | ✅ | MayTypography._applyScaler respects MediaQuery.textScalerOf |
| Reduced motion | ✅ | MayMotion.adapt() returns 3x duration; MaySkeleton notes reduced motion |

### Backend Code Quality

| Metric | Score | Notes |
|--------|-------|-------|
| TypeScript strict mode | ✅ | All compilerOptions enabled in tsconfig.json |
| ErrorCode enum parity | ✅ | Flutter (AppFailureCode) = TypeScript (ErrorCode): 12 matching codes |
| Error mapping to HttpsError | ✅ | AppError.toHttpsErrorDetail() maps correctly by error type |
| sanitizeMessage regex | ✅ | Email, phone, bank number patterns redacted |
| sanitizeMetadata field list | ✅ | amountMinor, ocrText, token, signature etc. blocked |
| Idempotency fingerprint hash | ⚠️ | Uses adler-like hash (32-bit) instead of SHA-256; collision risk for high-volume keys |

---

## 5. Defect Remediation Log

### Critical defects identified in Phase 0 codebase:

| # | Defect | Severity | Category | Status | Fix Required |
|---|--------|----------|----------|--------|-------------|
| D1 | household_auth.ts returns true unconditionally | CRITICAL | Security | OPEN | Implement actual RTDB membership check |
| D2 | Idempotency hash uses adler-like instead of SHA-256 | HIGH | Financial Integrity | OPEN | Use crypto.createHash('sha256') |
| D3 | index.ts imports non-existent module handlers | CRITICAL | Build | DOCUMENTED | Module handlers are Phase 1 scope per spec |
| D4 | No Firebase Emulator tests exist | MEDIUM | Testing | KNOWN | Documented as prerequisite for Phase 2 |
| D5 | Period key ignores timezone parameter | LOW | Domain Logic | OPEN | Apply offset in periodKey/weekKey |

### Medium defects:

| # | Defect | Severity | Status | Fix Required |
|---|--------|----------|--------|-------------|
| M1 | fromMajor(double) allows precision loss | LOW | DOCUMENTED | Accept String or int input instead |
| M2 | MaySegmentedControl missing VoiceOver labels | MEDIUM | PARTIAL | Add semanticsLabel per spec A15 |
| M3 | MayToast/Snackbar missing accessibility announcement | MEDIUM | PARTIAL | Add Semantics widget with label |

---

## 6. Test Execution Plan for Phase 1+

### Must be implemented before auth flow goes to production:
1. **Firebase Emulator test suite** — TC-001 through TC-043 (per specs/10)
2. **Backend unit tests** — money_validator, household_auth, idempotency_service, auth_context, structured_logger
3. **Flutter widget tests** — all 20 shared components × light/dark × normal/reduced-motion
4. **Flutter golden tests** — screen captures at narrow/wide × light/dark × 200% font

### Should be implemented before financial features:
5. **Money domain unit tests** — boundary conditions, large amounts, currency mismatch
6. **PercentageBps property tests** — threshold ordering, uniqueness validation
7. **Integration test for ledger event flow** — createLedgerEvent → projectLedgerEvent → query

---

## 7. Coverage Summary

| Metric | Count | Passing | Blocked | Not Started |
|--------|-------|---------|---------|-------------|
| Requirements (from matrix) | 52 | 14 VERIFIED | 6 BLOCKED | 32 NOT_STARTED/PARTIAL |
| Foundation components (A01-A24) | 24 | 15 fully verified | 0 | 6 partially/missing |
| Design tokens | 7 | 7 verified via inspection | 0 | 0 |
| Backend core modules | 7 | 3 verified | 4 | 0 |
| Flutter domain models | 4 | 3 verified | 1 (Period timezone) | 0 |
| CI/CD pipeline files | 9 | 8 verified | 1 (iOS provisioning) | 0 |

---

**Conclusion:** Phase 0 has solid foundation scaffold (design system, domain models, error model, CI/CD structure). However, no Flutter runtime tests or backend tests have been executed. The codebase is structurally sound but untested at the integration level. Phase 1 auth implementation requires emulator test coverage before production deployment.

**PHASE 0 TEST STATUS: PARTIALLY_COMPLETE** — Foundation verified by code inspection only; zero runtime tests executed.
