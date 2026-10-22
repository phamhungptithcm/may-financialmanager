---
name: may-financial-integrity
description: Review Mây double-entry immutable ledger, account transfers, budgets, assets, investment return calculations, household isolation and retries for production-safe money correctness.
---

# Money integrity execution

**Request:** $ARGUMENTS

Run reference preflight, read v2 architecture/RTDB schemas/Functions/contracts/security. Approved Mây HTML and FigJam UX Flow `.jam` determine the visible actions; verified contracts determine money semantics. Use actual FigJam board/export for route-dependent behavior, never assume PNG.

- Integer minor units only (VND exponent 0); balanced signed postings, immutable ledger, reversals/replacement for corrections.
- Stable request IDs with dedup; test two concurrent same requests, timeout/retry and crash after partial asynchronous processing.
- Transfers between owned accounts are neither expense nor income. Open balances, refunds, liability valuations and FX require correct independent semantics.
- Household RBAC at server boundary, strict cross-tenant tests; Admin SDK bypasses Rules. Projectors idempotent/replayable, reconciliation and recoverable checkpoints.
- Budget period timezone and threshold dedup, savings vs market growth (cashflow-adjusted performance), NO_DATA when not computable.
- Required evidence: unit tests, Firebase Emulator tests, concurrency tests and failure recovery. Unrun = BLOCKED. Never deploy or mutate production while validating.
