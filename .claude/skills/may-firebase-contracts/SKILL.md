---
name: may-firebase-contracts
description: Implement and audit TypeScript Firebase Functions v2, Realtime Database contracts, authenticated household access, RTDB and Storage rules, receipt OCR, FCM, billing and external provider adapters for Mây.
---

# Firebase contract and integration execution

**Request:** $ARGUMENTS

Before writes, read `CLAUDE.md`, v2 `03_ARCHITECTURE` through `08_SECURITY_PRIVACY`, `13_CONFIGURATION_RUNBOOK`, DTOs, schemas, RTDB/Storage draft rules and Functions matrix. Run reference preflight to ensure actual HTML and `.jam` are present; for user flows inspect approved FigJam/export first. Never read `.jam` as PNG.

Each handler must define: function ID, trigger, input DTO/runtime validation, RBAC permissions and App Check, idempotency, authoritative writes and ordering, projection changes, retries/DLQ, redacted telemetry, index, emulator and negative tests, failure/recovery. Admin SDK bypasses rules; enforce membership server side. Never trust client financial writes, OCR draft, or purchase price/entitlement.

Privacy: signed/private receipt uploads, MIME/byte validation, short TTL, OCR fallback/manual review, device token safety and quiet hours, store-notification signature validation and replay handling, consent and safe ad placement. Test emulator access control, household isolation, concurrent ledger operations, projection replay and revocations. No deployment/billing/secret changes without explicit owner authorization. Mark unconfigured providers BLOCKED in readiness checklist, not PASS.
