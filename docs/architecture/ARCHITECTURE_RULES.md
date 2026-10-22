# Architecture Rules — Mây Family Finance (Phase 0)

Generated: 2026-10-22. Derives from specs/03, 08, 11 and the approved HTML prototype.

---

## 1. Directory Structure

```
May/
├── apps/mobile/
│   ├── lib/
│   │   ├── app/
│   │   │   ├── may_app.dart          # MaterialApp/CupertinoApp bootstrap
│   │   │   ├── router.dart           # go_router config, routes, guards
│   │   │   └── environment.dart      # Environment enum, ConfigProvider
│   │   │
│   │   ├── core/
│   │   │   ├── constants/            # MayColors, app-wide constants
│   │   │   ├── errors/             # Result<T, AppError>, Failure model
│   │   │   ├── exceptions/         # Firebase-specific exceptions
│   │   │   ├── logging/            # Logger abstraction (no direct Firebase logs)
│   │   │   ├── utils/              # Date/time, currency formatting, string helpers
│   │   │   ├── validation/         # Shared validators (email, money, URL, etc.)
│   │   │   ├── localization/       # AppLocalizations (vi-VN default)
│   │   │   ├── security/           # App Check, secure storage helpers
│   │   │   └── extensions/         # Dart extension methods (DateTime, String, int)
│   │   │
│   │   ├── shared/
│   │   │   ├── design_system/
│   │   │   │   ├── tokens/           # MayColors, MaySpacing, MayRadius
│   │   │   │   ├── typography/       # MayTypography
│   │   │   │   ├── components/       # A01–A24 foundation widgets
│   │   │   │   ├── animations/       # MayMotion
│   │   │   │   └── transitions/      # Shared route/page transitions
│   │   │   │
│   │   │   ├── widgets/              # Higher-level shared widgets (not feature-specific)
│   │   │   ├── forms/                # Shared form helpers, field builders
│   │   │   ├── charts/               # Reusable chart primitives (donut, bar, line)
│   │   │   ├── layouts/              # Shared layout templates
│   │   │   └── state/                # Riverpod providers, base controllers
│   │   │
│   │   └── features/                 # Feature modules (one dir per feature)
│   │       ├── authentication/         # Auth screens + adapter
│   │       ├── household/              # Household CRUD
│   │       ├── accounts/               # Account management
│   │       ├── transactions/           # Transaction list, form, detail
│   │       ├── budgets/                # Budget create/list/detail
│   │       ├── analytics/              # Reports/charts
│   │       ├── wealth/                 # Assets, liabilities, investments, goals
│   │       ├── receipts/               # Camera, crop, review flow
│   │       ├── notifications/          # Inbox, settings
│   │       ├── home_widgets/           # Widget gallery, editor, OS bridge
│   │       ├── subscription/           # Mây Plus paywall, restore, manage
│   │       └── settings/               # Profile, data export/delete
│   │
│   ├── android/                        # Native Android config
│   ├── ios/                            # Native iOS config
│   ├── test/                           # Widget tests, golden baselines
│   └── integration_test/               # E2E against emulator
│
├── functions/
│   ├── src/
│   │   ├── index.ts                    # Trigger exports only (RTDB, scheduler, HTTP)
│   │   ├── core/                       # Shared infrastructure
│   │   │   ├── auth/                   # AuthContext, AppCheck verification
│   │   │   ├── authorization/          # HouseholdAuthorization, RBACPolicy
│   │   │   ├── errors/                 # AppError, ErrorCode, HttpsError mapping
│   │   │   ├── validation/             # Zod schemas, MoneyValidator, RequestValidator
│   │   │   ├── idempotency/            # IdempotencyService
│   │   │   ├── logging/                # StructuredLogger (correlationId-safe)
│   │   │   ├── money/                  # MoneyValidator, minor-unit utilities
│   │   │   └── firebase/               # FirebaseAdminProvider
│   │   │
│   │   ├── shared/                     # Cross-module shared types/utilities
│   │   │   ├── middleware/             # Auth middleware, RBAC gate, validator middleware
│   │   │   ├── contracts/              # Shared contract types (DTOs)
│   │   │   ├── events/                 # Event schemas & domain events
│   │   │   └── testing/                # Test helpers, fixtures
│   │   │
│   │   └── modules/                    # Business module handlers
│   │       ├── households/             # F01–F07
│   │       ├── accounts/               # F08–F10
│   │       ├── ledger/                 # F11–F15, F41
│   │       ├── budgets/                # F16–F17
│   │       ├── wealth/                 # F18–F25, F49
│   │       ├── receipts/               # F26–F29, F53
│   │       ├── notifications/          # F30–F34, F50
│   │       ├── widgets/                # F35–F36
│   │       ├── billing/                # F37–F40
│   │       └── maintenance/            # F42–F48
│   │
│   ├── test/                           # Unit + integration (emulator) tests
│   ├── package.json
│   └── tsconfig.json
│
├── packages/
│   └── contracts/                      # TypeScript + Dart shared type contracts
│       ├── src/                        # .ts source of truth
│       ├── schemas/                    # JSON Schema files for validation
│       └── dart/lib/                   # Auto-generated or parallel Dart models
│
├── docs/                               # Specs, architecture, QA
│   ├── architecture/                   # ADRs, architecture rules, inventory
│   ├── specs/                          # Authoritative v2 specifications
│   ├── qa/                             # Trace matrices, acceptance evidence
│   ├── firebase/                       # RTDB/Storage Rules, emulator config
│   ├── contracts/                      # domain-contracts.ts reference
│   ├── schemas/                        # JSON Schema per entity
│   └── prompts/                        # Phase prompts (copies)
│
├── .github/workflows/                  # CI: validate.yml, release.yml
├── scripts/                            # Pre-flight, inspection, audit scripts
├── pyproject.toml                      # Unrelated CocoIndex scaffolding (preserve)
└── main.py                             # Unrelated Python scaffold (preserve)
```

---

## 2. Dependency Rules

| Source Module | May Import From | Forbidden To Import From |
|---|---|---|
| `core/` | Only Dart SDK, approved Flutter SDK packages | Firebase directly; business logic |
| `shared/design_system/` | `core/`, Dart SDK, Flutter SDK | `features/`, Firebase |
| `shared/widgets/` | `core/`, `shared/design_system/` | Feature modules directly (except through repos) |
| `shared/state/` | `core/`, `shared/design_system/`, feature domains | Firebase types (use adapters) |
| `features/*/domain/` | Dart SDK, domain contracts package | Firebase, Flutter UI, sibling features |
| `features/*/application/` | `core/`, domain contracts, `shared/state/` | Flutter UI widgets; direct Firebase |
| `features/*/data/` | `core/`, domain contracts, `shared/state/` | Flutter UI widgets; sibling feature presentation |
| `features/*/presentation/` | `core/`, `shared/design_system/`, own domain/application | Other features' modules; Firebase directly |
| `functions/src/core/` | Node.js SDK, Admin SDK (in handlers) | Business modules (reverse only) |
| `functions/src/modules/*` | Own `core/`, shared middleware, contracts | Sibling modules, direct client-facing logic |

---

## 3. Financial Invariants (compiled from specs)

1. **Integer minor units only.** No floating-point money. VND exponent = 0.
2. **Balanced double-entry postings.** Every LedgerEvent's postings sum(deltaMinor) == 0 for the active currency.
3. **Immutable canonical events.** LedgerEvents are append-only; corrections create reversals + new events.
4. **Household isolation.** All admin operations verified via Firebase Admin SDK (bypasses RTDB rules).
5. **Idempotent commands.** Every command uses `clientRequestId`; identical payloads return same result, conflicting payloads return `DUPLICATE_CONFLICT`.
6. **Server-authorised roles.** Client-provided `role` is never trusted; always read from `/members/{hid}/{uid}` via Admin SDK.
7. **Receipts are drafts.** No auto-posting of OCR-extracted data without explicit user confirmation.
8. **Subscription verified server-side.** Entitlement derives only from cryptographically verified store events, not client claims.
9. **Period keys use household timezone.** Not device local clock. Default `Asia/Ho_Chi_Minh`.
10. **No financial PII in logs.** Structured logs carry correlation ID, function name, latency, outcome — never amounts, merchant names, or receipt OCR content.

---

## 4. Error Model (consistent across Flutter + Functions)

```ts
// TypeScript (functions)
interface AppError {
  code: ErrorCode;
  message: string;      // sanitized for client display
  correlationId: string;
  fieldErrors?: Record<string, string>;
  retryable: boolean;
}
type ErrorCode =
  | 'AUTH_REQUIRED'
  | 'VALIDATION_ERROR'
  | 'HOUSEHOLD_ACCESS_DENIED'
  | 'ROLE_DENIED'
  | 'ACCOUNT_NOT_FOUND'
  | 'CURRENCY_MISMATCH'
  | 'DUPLICATE_CONFLICT'
  | 'ALREADY_REVERSED'
  | 'RECEIPT_NOT_READY'
  | 'PURCHASE_UNVERIFIED'
  | 'RATE_LIMITED'
  | 'TEMPORARY_UNAVAILABLE'
  | 'INVARIANT_FAILED';

// Dart (mobile) — Result pattern
sealed class Failure {
  final String code;
  final String message;
  final String correlationId;
  final bool retryable;
}
enum AppFailureCode implements Failure { /* ErrorCode values */ }

Result<AcceptedCommand, Failure> → AcceptedCommand | Failure
```

---

## 5. State Management Strategy

- **Riverpod** as the sole state management approach.
- Controllers (`@riverpod`) use **repositories** that abstract Firebase behind interfaces.
- UI reads `AsyncValue<T>` from controllers — never subscribes to Firebase streams directly.
- Every controller handles all states: `loading`, `data`, `error`. No silent exception swallowing.

---

## 6. Testing Strategy

| Layer | Tool/Framework | Target |
|---|---|---|
| Dart domain unit | `dart test` (mockito) | Money, Period, PostingEngine, validators |
| TypeScript service unit | `vitest` (zod-valibot mock) | RBAC, validation, idempotency, money |
| Firebase Emulator integration | `firebase emulators:exec` | RTDB rules, callable auth fakes, Storage policies |
| Contract tests | Custom harness | TS ↔ Dart model parity, snapshot diffs |
| Flutter widget/golden | `flutter test`, `golden_toolkit` | All screens light/dark, 3 device widths, 200% text |
| E2E | `integration_test` (Flutter) | Sign-in → household → transaction flow |
| Security | Custom harness + emulator | Cross-tenant access, privilege escalation, malformed payloads |
| Load/resilience | Custom harness + emulator | Concurrency, offline retry, projector lag |

---

## 7. Completion Criteria for Phase 0

- [x] Component inventory exists (`docs/architecture/COMMON_COMPONENT_INVENTORY.md`)
- [ ] Shared component APIs documented (inventory serves as API spec)
- [ ] Design tokens extracted from approved prototype and implemented in Flutter
- [ ] Application architecture initialised (app shell, router, environment config)
- [ ] Domain foundation built (Money, Period, PercentageBps with full tests)
- [ ] Firebase client foundation interfaces defined (repositories, contracts)
- [ ] Cloud Functions common infrastructure scaffolded (auth, authorization, validation, money)
- [ ] Shared contracts package created (`packages/contracts/`)
- [ ] Testing infrastructure configured (Dart + TS unit test frameworks)
- [ ] CI pipeline configured (`validate.yml` with lint/typecheck/unit/emulator gates)
- [ ] Firebase emulator configuration works (Auth, RTDB, Functions, Storage)
- [ ] No critical duplication in foundational code

---

## 8. Blockers for Phase 1

| Blocker | Status | Resolution |
|---|---|---|
| FigJam flow export manifest missing | BLOCKED | Requires manual Figma read or approved export |
| Firebase project dev/staging/prod accounts | EXTERNAL | Owner-configured before feature implementation |
| Apple Developer Program / Google Play Console | EXTERNAL | Required for store verification (Phase 6) |
| Flutter SDK installed and configured | CHECK | Run `flutter doctor` after files are in place |
