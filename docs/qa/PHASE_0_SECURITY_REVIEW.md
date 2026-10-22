# Phase 0 Security Review

**Audit date:** 2026-10-22  
**Auditor:** Claude Code (automated security audit via code inspection)  
**Classification framework:** CRITICAL / HIGH / MEDIUM / LOW / INFO

---

## Executive Summary

Phase 0 has a **well-designed security architecture** at the specification and scaffolding level. However, the **authorization layer contains a known placeholder that bypasses all checks**. The infrastructure (CI/CD secrets scanning, Firebase rules skeleton, error model) is solid. Below is the detailed audit.

---

## 1. Authentication & Authorization (RBAC)

### Finding: CRITICAL-01 — `checkHouseholdAccess()` returns true unconditionally
| Field | Value |
|-------|-------|
| Severity | **CRITICAL** |
| File | functions/src/core/authorization/household_auth.ts:31 |
| Description | `checkHouseholdAccess()` always returns `true` — no actual membership check against RTDB `/members/{hid}/{uid}`. Code contains a TODO comment acknowledging this is an MVP placeholder. |
| Attack vector | Any authenticated user can call any callable function targeting any household. No tenant isolation. |
| Impact | **Full cross-tenant data leak.** User in household A can read/write all data for households B, C, etc. |
| Remediation | Implement actual Admin SDK RTDB lookup. Compare member status against 'ACTIVE'. Throw `HOUSEHOLD_ACCESS_DENIED` on mismatch. Remove return-true placeholder. |
| Status | **OPEN — Must fix before any auth flow production deployment** |

### Finding: HIGH-01 — App Check validation is a no-op trust
| Field | Value |
|-------|-------|
| Severity | **HIGH** |
| File | functions/src/core/auth/auth_context.ts:51–56 |
| Description | `validateAppCheck()` checks if token is non-null but does NOT verify it against Firebase App Check service. All requests with any non-null value pass. |
| Attack vector | Fake client apps can send arbitrary tokens to bypass App Check enforcement. |
| Impact | Bypass of device attestation — compromised or custom clients could invoke Cloud Functions directly. |
| Remediation | Verify App Check token via Firebase Admin SDK's `appCheck().verify()` method. Return error on invalid/expired/revoked tokens. |
| Status | **OPEN** (marked as MVP delegation to runtime enforcement; acceptable only if enforced at Functions deploy config level) |

### Finding: MEDIUM-01 — Auth token type stored but not fully validated
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | functions/src/core/auth/auth_context.ts:20–28 |
| Description | `getAuthInfo()` extracts uid from `context.auth.uid` but stores the full auth token. The token type is not validated (e.g., Firebase Auth vs custom token). |
| Impact | Minimal — UID is correctly extracted, and Firebase Functions runtime validates token authenticity before passing to handler. |
| Remediation | Add check for `token.viat < now` (expired tokens) and `token.app_check === true`. |
| Status | **LOW RISK** — Firebase Functions runtime already validates auth; this is a defensive coding improvement. |

---

## 2. Database Security Rules

### Finding: INFO-01 — RTDB rules skeleton present but untested
| Field | Value |
|-------|-------|
| Severity | **INFO** (documented) |
| File | docs/firebase/database.rules.json |
| Description | 40+ resource paths defined with read/write rules. All follow the pattern: member-status ACTIVE check for tenant-scoped data, admin-only for sensitive paths. No client write on ledgerEvents, idempotency, purchaseEvents, auditLogs, deviceTokens. |
| Issue | Rules are NOT tested against Firebase Emulator integration tests. The spec requires 15 specific security scenarios (TC-035 through TC-044). None executed. |
| Specific gaps: | - No `.write` rules on most paths (defaults to deny — correct, but should be explicit) |
| | - `widgetLayouts` allows client write with only UID check — schema not validated by rules |
| | - `notificationSettings` has no schema enforcement in rules |
| Status | **BLOCKED** — requires Firebase Emulator test execution (Phase 2 prerequisite) |

### Finding: MEDIUM-02 — Query-bounded reads use fragile rule syntax
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | database.rules.json:118,132 |
| Description | `transactionList` and `accountMovements` rules reference `query.orderByChild` and `query.limitToLast` in the `.read` expression. RTDB Security Rules evaluate these as path variables (which are `$ym`), not as query parameters. This rule may silently pass or fail unpredictably. |
| Impact | Data access may be incorrectly granted/denied for bounded queries. |
| Remediation | Use proper RTDB query parameter syntax: `auth != null && root.child('members').child($hid).child(auth.uid).child('status').val() === 'ACTIVE'` (remove the query comparison which doesn't work in `.read`). |
| Status | **OPEN — Rules must be corrected and tested** |

---

## 3. Storage Security

### Finding: INFO-02 — Storage deny-all with documented signed URL flow
| Field | Value |
|-------|-------|
| Severity | **INFO** (correctly designed) |
| File | docs/firebase/storage.rules |
| Description | Deliberate `allow read, write: if false` on all paths. Signed GCS URLs minted by Cloud Functions after authorization verification. TTL, path, method restrictions documented in rules comments. |
| Assessment | **Correct design pattern.** Matches spec FR-15 (Storage Rules). No gaps. |
| Status | ✅ **CORRECT BY DESIGN** — requires only signed URL implementation in Cloud Functions. |

---

## 4. Error Handling & PII Leakage Prevention

### Finding: MEDIUM-03 — Error sanitization could be bypassed
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | functions/src/core/errors/app_error.ts:84–98 |
| Description | `sanitizeMessage()` uses regex for email, phone, and bank number patterns. If an error message doesn't contain a pattern that matches these specific regexes, PII could be logged. |
| Attack vector | Error messages containing raw financial amounts (e.g., "Balance: 999,000,000 VND") — the `\d{12,}` pattern would only match numbers with 12+ digits. |
| Remediation | Add amount-specific redaction: `/\d{1,3}(?:,\d{3})+(?= VND| USD|\b)/g`. Also add a general warning: amounts in error messages should be avoided entirely by callers. |
| Status | **OPEN** — improve PII coverage in sanitizeMessage |

### Finding: INFO-03 — Logger sanitization covers critical fields
| Field | Value |
|-------|-------|
| Severity | **INFO** (positive finding) |
| File | functions/src/core/logging/structured_logger.ts:76–82 |
| Description | `SENSITIVE_FIELDS` includes: amountMinor, totalMinor, balanceMinor, ocrText, receiptContent, merchantRaw, token, fcmToken, deviceToken, signature, signedPayload, jws, rawPayload. Email-like values auto-redacted by regex. |
| Assessment | **Good coverage.** The last-line-of-defense approach is correct per spec operational requirements. |
| Status | ✅ **CORRECT** (with enhancement note above) |

---

## 5. Financial Integrity — Security Boundaries

### Finding: HIGH-02 — Idempotency fingerprint hash is not cryptographically stable
| Field | Value |
|-------|-------|
| Severity | **HIGH** |
| File | functions/src/core/idempotency/idempotency_service.ts:73–80 |
| Description | `hash()` uses a simple adler-like integer hash (32-bit). For idempotency deduplication, deterministic collision resistance matters — same payload must always produce the same hash. While this hash IS deterministic, collisions are statistically likely at scale (birthday paradox: ~1 collision in 65,536 keys). |
| Impact | Potential for **false duplicate detection** — two different payloads could map to the same fingerprint, causing rejection of valid requests or double-posting. |
| Remediation | Use `crypto.createHash('sha256')` from Node.js built-in crypto module. SHA-256 provides 2^128 collision resistance (birthday bound). |
| Status | **OPEN** — must fix before ledger operations are implemented. |

### Finding: MEDIUM-04 — Money validator accepts NaN/Infinity via `typeof` check only
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | functions/src/core/money/money_validator.ts:17 |
| Description | `validateMoneyAmount()` checks `!Number.isSafeInteger(amountMinor)`. This is correct — NaN, Infinity, floats are all rejected. However, if the caller passes a string that coerces to a number before this check (e.g., via Zod schema), validation could be bypassed. |
| Impact | Minimal — Zod's `.number().int()` should catch this in request validation layer. |
| Remediation | Add explicit `Number.isInteger()` + `Number.isSafeInteger()` check at the beginning of the validator chain before Zod schemas. Document that all monetary inputs must pass through this validator. |
| Status | **LOW RISK** — Zod schema validation is the primary guard; this is a defense-in-depth note. |

---

## 6. CI/CD Security

### Finding: INFO-04 — gitleaks + trivy configured correctly
| Field | Value |
|-------|-------|
| Severity | **INFO** (positive) |
| File | .github/workflows/reusable-quality-gates.yml:162–190 |
| Description | Gitleaks scans for secret patterns. Trivy scans filesystem for vulnerabilities and dependencies (report-only, not blocking on deps). Both run in all environments. |
| Assessment | **Correct.** gitleaks uses GITHUB_TOKEN (least privilege). Trivy dep-scan is advisory only (exit-code: 0) which is reasonable for early-stage project. |
| Status | ✅ **CORRECT** |

### Finding: MEDIUM-05 — CI/CD permissions could be more restrictive
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | .github/workflows/main-release.yml:29–31 |
| Description | Main Release workflow has `contents: write` (needed for tag + release). Branch CI has `contents: read, checks: write` (correct least privilege). However, the reusable-quality-gates workflow does NOT declare permissions explicitly — it inherits caller's permissions. If called from main-release.yml, all jobs get `contents: write`. |
| Impact | gitleaks/trivy scans in quality gates would have `contents: write` when run from release pipeline (the scan job doesn't need write access). |
| Remediation | Add explicit `permissions:` block to reusable-quality-gates.yml with minimal permissions for each job. |
| Status | **OPEN** — improve CI least privilege |

### Finding: INFO-05 — No Firebase deployment in any workflow
| Field | Value |
|-------|-------|
| Severity | **INFO** (positive) |
| File | All workflow files |
| Description | Confirmed: NO `firebase deploy` command exists in any CI workflow. Production Firebase requires manual deployment per spec. |
| Assessment | **Correct by design.** Prevents accidental production deploys. |
| Status | ✅ **CORRECT** |

---

## 7. Secrets Management

### Finding: LOW-01 — .env.example has no real secrets (correct)
| Field | Value |
|-------|-------|
| Severity | **LOW** (positive note) |
| File | .env.example |
| Description | Template contains placeholder values only. No API keys, passwords, or secret prefixes with actual values. |
| Status | ✅ **CORRECT** |

### Finding: MEDIUM-06 — No Secret Manager integration for development
| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | infra/, docs/firebase/firebase.json.example |
| Description | Firebase project configuration examples reference local config files. Secret Manager integration documented as example only, not implemented. |
| Impact | Developers must configure environment locally (acceptable for dev/staging). Production deployment will need Secret Manager setup. |
| Status | **DOCUMENTED** — expected for scaffold phase; must be addressed before staging/prod setup. |

---

## 8. Threat Model Compliance (from specs/08)

| Threat | Example | Control | Implemented? | Verified? |
|--------|---------|---------|-------------|-----------|
| Cross-tenant IDOR | `hh_A` reads `hh_B` | Member check + RTDB rules | ⚠️ Placeholder only | NO |
| Client forges VIP | Edit local bool/RTDB | Deny rules writes + store verification | ✅ Rules skeleton | NO emulator test |
| Duplicate transaction | Network retry | Request ID + immutable event + reconcile | ⚠️ Schema defined, no handler | NO |
| Balance corruption | Parallel upserts | Zero-sum postings + reconciliation | ✅ Validator present | NO integration test |
| Receipt exfiltration | Public URL or logs | Storage private + short TTL | ✅ Deny-all rules | NO emulator test |
| Fake OCR text | Malicious instructions | JSON parse untrusted data | ⚠️ Schema defined | NO handler |
| Notification leak | Lock-screen amounts | Push payload filtering | ⚠️ Design noted in logger | NOT IMPLEMENTED |
| Store webhook forgery | HTTP post = renewed | JWS/OIDC validate + provider check | ⚠️ Webhook handler commented out | NOT IMPLEMENTED |
| Invite brute-force | Code enumeration | Crypto nonce + TTL + rate limit | N/A (invite flow not implemented) | — |
| Device token takeover | Victim token reuse | UID+device association | ⚠️ deviceTokens path deny-all | NO emulator test |
| Refund abuse | Offline still Plus | Entitlement expiry + webhook replay | ⚠️ entitlements path rules present | NOT IMPLEMENTED |
| Malicious files | File bomb/invalid MIME | Upload max + content sniff | ⚠️ Storage rules deny-all | Handler not implemented |
| Data inference from ads | Category used for targeting | No sensitive fields to AdMob | ✅ Documented in logger sanitization | NOT TESTED |

---

## 9. Security Review Summary

### Critical/High findings:

| # | Finding | Severity | Status | Priority |
|---|---------|----------|--------|----------|
| CRIT-01 | household_auth.ts returns true | **CRITICAL** | OPEN | P0 — Block auth deployment |
| HIGH-02 | Idempotency hash not SHA-256 | **HIGH** | OPEN | P0 — Before ledger implementation |
| HIGH-01 | App Check validation no-op | **HIGH** | OPEN | P1 — Enable at Functions config level |

### Medium findings:

| # | Finding | Severity | Status | Priority |
|---|---------|----------|--------|----------|
| MED-02 | RTDB query rule syntax incorrect | **MEDIUM** | OPEN | P1 |
| MED-03 | Error sanitization gap for amounts | **MEDIUM** | OPEN | P2 |
| MED-05 | CI permissions inheritance | **MEDIUM** | OPEN | P2 |
| MED-06 | Secret Manager not configured | **MEDIUM** | DOCUMENTED | P2 (pre-deployment) |

### Positive findings:
- ✅ Storage rules correctly deny-all with signed URL pattern
- ✅ Error model consistent across Flutter and TypeScript (12 matching error codes)
- ✅ Structured logger includes comprehensive PII field list
- ✅ CI/CD gitleaks + trivy configured correctly
- ✅ No Firebase deployment in any CI workflow
- ✅ .env.example contains no real secrets
- ✅ No hardcoded secrets found in codebase
- ✅ Money validator enforces safe integer, positive amount, currency matching

---

## 10. Recommendation

**Phase 0 security architecture is well-designed at the specification level.** The implementation provides:
- Correct error model and PII redaction patterns
- Proper Firebase rules skeleton (deny-all by design)
- Sound CI/CD with secret scanning
- Financial integrity validators (Money, percentageBps, moneyValidator)

**The single CRITICAL blocker is `household_auth.ts` returning true unconditionally.** This must be fixed before Phase 1 auth implementation.

**Recommended order:**
1. Implement actual household authorization (CRIT-01)
2. Upgrade idempotency hash to SHA-256 (HIGH-02)
3. Enable App Check verification at Functions runtime config (HIGH-01)
4. Correct RTDB query rule syntax (MED-02)
5. Write Firebase Emulator security tests (all findings need emulator validation)

**PHASE 0 SECURITY STATUS: PARTIALLY_COMPLETE** — Architecture verified, critical placeholder acknowledged and documented, infrastructure correct but untested.
