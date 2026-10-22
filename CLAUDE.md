# Mây Family Finance — Claude Code operating instructions

**Product identity approved by owner:** `docs/FamilyClanMockupFullFlow.html` IS the authoritative **Mây financial app prototype** despite its historical `FamilyClan` filename. Do not rename, replace, reinterpret as a genealogy app, or silently rewrite it.

**This repository starts as specification-only.** `main.py` and `pyproject.toml` are unrelated CocoIndex scaffolding. Create Flutter and Firebase code deliberately in `apps/mobile/` and `functions/` as approved by the implementation plan; do not treat the Python scaffold as the mobile backend.

Read `AGENTS.md` and relevant `docs/specs/*` before editing. Follow `.claude/rules/*` and invoke the appropriate project skills.

## Immutable authority map
1. **UI, exact copy, visuals, gestures, animation, transition:** `docs/FamilyClanMockupFullFlow.html` (read DOM/CSS/JS AND exercise in browser).
2. **Navigation topology, branches and user journeys:** `docs/Family Finance — End-to-end UX Flow.jam` (FigJam source). A `.jam` file is NOT a PNG. To verify connections use a readable FigJam board via connected Figma or an approved export and provenance in `docs/qa/design-references/`. Without one, UI flow work is BLOCKED.
3. **Functional requirements and UI screen IDs:** `docs/specs/01_PRD.md`, `02_UI_UX.md`, `09_COMPONENT_LIBRARY.md`.
4. **Backend, money semantics, schemas, APIs, security, integrations:** `docs/specs/03_ARCHITECTURE.md` through `08_SECURITY_PRIVACY.md`, plus `docs/contracts/*`, `docs/schemas/*`, `docs/firebase/*`.
5. **Verification, release and configuration:** `docs/specs/10_TESTING_ACCEPTANCE.md`, `11_DELIVERY_PLAN.md`, `12_PRODUCT_ANALYTICS.md`, `13_CONFIGURATION_RUNBOOK.md`, `docs/qa/*`.
6. `docs/reference/*_v1.md` is historical and NEVER overrides v2.

Conflicts: backend contracts govern money and security; approved HTML governs rendered UI; *verified* FigJam source governs journey edges. Record conflicts in `docs/qa/REFERENCE_CONFLICTS.md`; do not guess or make silent changes.

## Mandatory gates before changes
- Run `python3 scripts/reference_preflight.py --strict` (and `--lock-check` when a reviewed lock exists).
- Before **UI route/flow implementation**, run `python3 scripts/reference_preflight.py --strict --require-flow-export`; an inspectable Figma board may be used for analysis, but an approved export is still needed for reproducible CI visual evidence unless an approved ADR documents another reproducible artifact.
- Read actual HTML via `python3 scripts/inspect_mockup.py` and browser; do not copy generic Flutter screens or build a WebView clone.
- Map each slice: requirement → HTML screen/selector → FigJam node/edge → Flutter route/state → Cloud Function → RTDB paths/rules → tests/evidence.
- For existing code, inspect git status and preserve changes. Work in small vertical slices, not a speculative mass generation.

## Financial/security invariants
- Flutter/Dart app for iOS/Android; Functions v2 TypeScript, Firebase Realtime Database, Firebase Auth, App Check, private Storage, FCM. Google/Apple provider setup must be explicitly configured; no fabricated integration claims.
- HouseholdId privacy boundary, server-side RBAC in all financial Cloud Functions (Admin SDK bypasses RTDB Rules).
- Immutable double-entry balanced ledger, integer currency minor units (VND exponent 0), idempotent request IDs, compensating reversals, replayable projections and reconciliation. No client canonical ledger writes.
- Receipt OCR is a draft until the user verifies and confirms; always support manual entry.
- No secrets, raw receipt data, personal finances or financial amounts in logs/analytics/push lock screens. Minimize third-party data.
- Mây Plus entitlement per-user, backend-verified, ad-free; 19,000 VND/month and 190,000 VND/year are TARGET prices, real storefront prices must be shown in purchases.
- NEVER deploy, publish, modify production Firebase rules/database, rotate secrets or perform irreversible operations without explicit owner approval.

## Completion is evidence-based
Run available analyzers, automated tests, Firebase Emulator rules tests, Flutter integration tests and same-viewport screenshot/motion comparisons. Record PASS/FAIL/BLOCKED accurately in `docs/qa/UI_FLOW_MATRIX.csv` and `docs/qa/BACKEND_TRACE_MATRIX.csv`. Missing visual flow export, device runtime or emulator = BLOCKED, never PASS. Never claim 100% UI fidelity without owner-reviewed evidence.

Use `/may-implement-feature`, `/may-ui-fidelity`, `/may-ux-flow-audit`, `/may-firebase-contracts`, `/may-financial-integrity`, and `/may-release-gate` as appropriate. Start with Phase 0 audit; do not invent an existing Flutter application.

## Foundation-First and Reuse-First Policy

All implementation must follow:

Foundation → Shared Components → Domain Components → Features.

Before introducing a new component or service:

1. Search for an existing implementation.
2. Review the shared component inventory.
3. Prefer reuse or composition.
4. Avoid duplicate responsibilities.
5. Keep domain-specific behavior inside its domain.
6. Follow established design tokens and API contracts.
7. Add tests for shared behavior.
8. Update component documentation when public APIs change.

The approved HTML prototype is the visual source of truth.

Never introduce inconsistent colors, spacing, typography,
animations, transitions, buttons, forms, or navigation.

All features must use the shared design system.

All Firebase Functions must reuse common authentication,
authorization, validation, logging, and error-handling
infrastructure.

Do not create abstractions solely for hypothetical reuse.

Shared components must remain independent of individual
feature implementations.

Any exception requires a documented architectural reason.

## Common vs Feature-Specific Architecture Policy

All implementation MUST follow the Foundation-First
and Reuse-First principles.

### Component Classification

Every new component, service, utility, or abstraction
must be classified before implementation:

1. GLOBAL SHARED
   Reusable across unrelated features.

2. SHARED DOMAIN
   Reusable across features within the same domain.

3. FEATURE-SPECIFIC
   Owned by one feature and containing its business logic.

### Mandatory Rules

- Search existing implementations before creating new ones.
- Reuse shared components whenever appropriate.
- Never duplicate common UI primitives or infrastructure.
- All UI must use the centralized design system.
- Never hardcode colors, typography, spacing, or animations.
- Keep domain-specific logic out of generic components.
- Feature-specific modules must not depend on each other's internals.
- Shared modules must never import feature-specific implementations.
- Prefer composition over inheritance.
- Avoid premature abstractions and overengineering.
- Promote components to shared only when genuine reuse exists.
- Changes to shared components must not break existing consumers.
- Shared components require appropriate automated tests.
- Any architectural exception must be documented.

### Before Writing Code

Claude MUST:

1. Identify the responsibility of the new implementation.
2. Search for existing reusable implementations.
3. Classify it as GLOBAL, SHARED DOMAIN, or FEATURE.
4. Verify dependency boundaries.
5. Reuse existing design tokens and contracts.
6. Implement and test.
7. Check for duplication and architectural drift.

Detailed rules:

.claude/rules/common-vs-feature.md

These rules apply to every implementation phase.

## CI/CD and Release Governance

Mây Family Finance uses exactly two logical CI/CD pipelines:

### Branch CI
- Trigger: any non-main branch push or PR targeting main.
- Run build, analysis, tests, security and artifact validation.
- Never create Git tags or GitHub Releases.
- Never deploy production.

### Main Release
- Trigger: push to main.
- Run the same mandatory quality gates as Branch CI.
- Create a Git tag and professional release notes only after
  every required check passes.
- Publish a GitHub Release with validated artifacts.
- Never deploy Firebase, App Store or Google Play automatically.

### Mandatory Release Rules
- Reuse common CI scripts and quality gates.
- Use deterministic semantic versioning.
- Prevent duplicate tags and releases.
- Never force-push or overwrite release tags.
- Never bypass failed tests.
- Never expose secrets.
- Never claim pipeline success without execution evidence.
- Protect main using GitHub branch rules.
- Require explicit approval before the first real release publication.

Every CI/CD change must follow:
Implement → Review → Test → Fix → Retest → Verify.


## Phase Completion and Readiness Gate

No development phase may be marked COMPLETE
without implementation and verification evidence.

Before moving to the next phase, Claude must:

1. Reconstruct all requirements from approved specs.
2. Verify implementation against source code.
3. Execute all applicable automated tests.
4. Verify integration and security boundaries.
5. Review UI against approved design references.
6. Resolve all actionable critical/high findings.
7. Validate CI/CD and architecture compliance.
8. Record verification evidence and outstanding issues.
9. Produce a formal phase readiness report.

A passing build alone does not establish
phase completion.

Unexecuted tests are NOT passed tests.

Mocked tests are NOT integration tests.

Documentation-only implementation is NOT complete.

If a mandatory acceptance criterion is unverified,
the next phase must not start.

The next phase requires a READY readiness decision
and explicit authorization to proceed.

## Phase Completion and Readiness Gate

No development phase may be marked COMPLETE
without implementation and verification evidence.

Before moving to the next phase, Claude must:

1. Reconstruct all requirements from approved specs.
2. Verify implementation against source code.
3. Execute all applicable automated tests.
4. Verify integration and security boundaries.
5. Review UI against approved design references.
6. Resolve all actionable critical/high findings.
7. Validate CI/CD and architecture compliance.
8. Record verification evidence and outstanding issues.
9. Produce a formal phase readiness report.

A passing build alone does not establish
phase completion.

Unexecuted tests are NOT passed tests.

Mocked tests are NOT integration tests.

Documentation-only implementation is NOT complete.

If a mandatory acceptance criterion is unverified,
the next phase must not start.

The next phase requires a READY readiness decision
and explicit authorization to proceed.
