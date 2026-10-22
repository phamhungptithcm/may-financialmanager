---
name: may-implement-feature
description: Deliver one Mây Finance feature end to end in Flutter and Firebase, traceable to the approved HTML UI, the real FigJam .jam user journey, v2 domain/API/RTDB contracts and automated acceptance tests.
---

# Implement a safe feature vertical slice

**Feature/phase:** $ARGUMENTS

## Inspect
- Read `CLAUDE.md`, `AGENTS.md`, `docs/README.md`, v2 relevant specs, existing code/branch status.
- Run `python3 scripts/reference_preflight.py --strict` and optionally `--lock-check`; BEFORE a UI flow use `--require-flow-export`. The HTML `docs/FamilyClanMockupFullFlow.html` is confirmed as actual Mây design. The `.jam` is opaque until inspected using Figma or a verified readable export.
- Audit browser behavior of original HTML; map FigJam node/edge from evidence. Inventory requirement IDs, screen IDs, backend function IDs, DTO/schema, storage/RTDB security and TC IDs. Report missing evidence as BLOCKED.

## Plan and implement
- Propose concrete small change set and acceptance, then implement contract validation → Auth+App Check+RBAC → durable idempotent ledger/events/projections → Flutter repository/provider → native screen components/motion → tests.
- Observe monetary invariants, OCR confirmation gate, no-ad verified subscription, limited financial data exposure; mock external integrations only when explicitly labeled as mock.
- Do not modify originals, invent an implemented app (repo starts as specs only), or replace Flutter with WebView.

## Verify
- Run available Dart/Flutter, TypeScript, Firebase Emulator, security, integration and UI screenshot/transition tests. Separate PASS/FAIL/BLOCKED and store evidence.
- Bring in `/may-ui-fidelity`, `/may-ux-flow-audit`, `/may-firebase-contracts`, `/may-financial-integrity` and independent subagent reviews as needed.
- Update `docs/qa/UI_FLOW_MATRIX.csv` and `docs/qa/BACKEND_TRACE_MATRIX.csv` only with proven rows. Never claim 100% fidelity without evidence and owner review.

**Final:** feature IDs | exact HTML+FigJam sources | Flutter routes | API/DB updates | tests | UI/motion evidence | risks/ADRs | blockers.
