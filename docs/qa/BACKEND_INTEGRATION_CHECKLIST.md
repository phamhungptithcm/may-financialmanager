# Backend and 3rd-Party Contract Review

Use alongside `docs/specs/03_ARCHITECTURE.md`, `04_RTDB_SCHEMA.md`, `05_FUNCTIONS_CATALOG.md`, `06_API_CONTRACTS.md`, `07_INTEGRATIONS.md`, `08_SECURITY_PRIVACY.md`, `13_CONFIGURATION_RUNBOOK.md` and reference UI/flow. Record each handler in `BACKEND_TRACE_MATRIX.csv`.

## Flutter → Firebase Functions v2 → RTDB
- [ ] UI action maps to specific Function and typed DTO; Auth, App Check, role and household membership verified *inside* handler.
- [ ] Server-side schema validation and structured, localized/safe error responses.
- [ ] Canonical ledger event append-only, balanced, minor-unit integer, unique idempotency key; correction via reversal.
- [ ] RTDB event indexes, read projection, cursor paging, membership/read-only permissions; no client writes to canonical ledger.
- [ ] Functions replay/retry/concurrency behavior tested on emulator; projection rebuild reconciles snapshots.
- [ ] Multi-household data isolation; Storage rules and signed upload proof; deletion/retention.

## Third parties
- [ ] Firebase Auth (Apple/Google/phone where specified) and provider linking/revocation.
- [ ] OCR provider selection benchmarked on *Vietnamese receipts*; low confidence → edit → confirm; failed OCR → manual entry.
- [ ] FCM + APNs on actual iOS/Android devices; dedup, quiet hours, locale, no amounts in lock screen.
- [ ] StoreKit 2 / Play Billing: verified sandbox renewals, restore, grace, refunds, cancellation; entitlement persists as server-authoritative.
- [ ] AdMob and consent flows including UMP/ATT; verified VIP suppresses ads, no finance payloads leaked to ad SDKs.
- [ ] WidgetKit and Android Glance: privacy redaction, refresh budgets and unavailable data state.
- [ ] Crashlytics/Analytics privacy, alerting, quotas, cost, timeout/retry, webhook signature checks and DLQ.
- [ ] Migration, backup/restore and rollback tested; no live deploy without approval.

Include file/line evidence, emulator logs and assertions. Unsupported integration, missing credentials or simulated paths are **BLOCKED/SANDBOX**, not production complete.
