# Mây — Agent Execution Contract

## Source authority
- Owner confirmed `docs/FamilyClanMockupFullFlow.html` is the authentic Mây Finance prototype. The filename is not a reason to reject or replace it.
- The original `docs/Family Finance — End-to-end UX Flow.jam` is the flow design source. It is NOT a PNG and cannot be safely interpreted by filename alone. Examine the real FigJam board with Figma tools when available, or an owner-reviewed export with provenance. Never hallucinate flows.
- `docs/specs/` and canonical contracts govern business behaviors, Firebase paths, security and tests. `docs/reference/` v1 is secondary/historical.

## Standard lifecycle
1. Read `CLAUDE.md`, project `docs/README.md`, phase docs and current code. Record `git status`.
2. Run the preflight. For UI tasks, require readable flow export or document a verified Figma read artifact under an ADR and obtain reviewer sign-off.
3. Inventory actual HTML screens, CSS tokens, DOM interactions, JS state, transitions and motion; exercise it in the browser.
4. Inventory exact FigJam nodes/edges, branch labels, exceptions and deep-links from verified evidence. Record in trace matrix.
5. Build a small feature contract and identify authorization, idempotency, persistence, UI states, motion, tests, error handling and rollback.
6. Implement native Flutter components, Functions v2, RTDB rules/projections and external adapters as applicable. Never build a WebView around the HTML reference.
7. Test independently: static checks, unit/integration, Emulator security, retry/concurrency, screen compare/interaction, accessibility and reduced motion.
8. Obtain read-only review from specialized subagents when relevant. Log evidence and remaining blockers. Ask owner approval for destructive or production actions.

## Architecture invariants
- Integer minor units only; VND exponent 0. Balanced double-entry postings, immutable canonical events, reversals for correction. Stable idempotency keys and replay/reconciliation for projections.
- Household isolation and least privilege: verified user/role checks at function boundary and within service; Firebase Admin SDK bypasses Rules.
- OCR suggestions do not post finance transactions. Receipt review + explicit approval required.
- Ad-free entitlement only after validated store events. Separate product target price from actual StoreKit/Play storefront price.
- Private receipts; data-minimized telemetry/push. All provider keys in Secret Manager or supported encrypted configuration.
- Never assume cross-path RTDB updates are a general replacement for transactional domain locking; document atomicity strategy and failure recovery per command.

## UI quality
- Responsive visual comparison at same viewport, device pixel ratio, font fallback and OS safe areas. Track interaction/motion contracts from HTML source and browser observations; do not invent animation values.
- Support loading, empty, validation, permissions, failures, offline retry, privacy redaction and reduced motion. Use concise Vietnamese visible text and English code identifiers.
- When `.jam` board can't be inspected: mark route/flow **BLOCKED**; do not present spec descriptions as observed graph evidence.

## Non-destructive behavior
- Protect `docs/FamilyClanMockupFullFlow.html`, the `.jam` flow, the approved lock, original specs and provider configuration. Propose ADR for conflicting changes; never rewrite authoritative files to make tests pass.
- Never claim Firebase/prod integration works when credentials are TBD. Do not deploy or make real purchases without explicit authorization.

## Required report for each feature
`Requirements/IDs | Source evidence (HTML + FigJam) | Flutter routes/components | API/Functions/DTO | RTDB/rules | Tests PASS/FAIL/BLOCKED | Visual/flow evidence | Security review | Conflicts/ADRs | Remaining actions`.
