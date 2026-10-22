# Phase Prompts — use AFTER MASTER_PROMPT

Each prompt is self-contained enough to paste into a coding agent working in the project repository. The agent must re-read the relevant v2 specifications, keep the architecture invariant and run real tests. Complete one phase and review its evidence before moving to the next.

## PHASE 0 — Repo, toolchain, Firebase emulator, CI
Implement foundation from `specs/00`, `specs/03`, `specs/10`, `specs/11`: Flutter + Dart app, Firebase Functions v2 TypeScript + Zod strict, contracts package, environment configs, Auth/RTDB/Functions/Storage emulator, GitHub Actions, lint/typecheck/test, secure secret manager instructions. Create locale vi-VN and `MayTheme` skeleton. Zero hardcoded credentials. Provide exact run commands and screenshots/app startup evidence. Smoke test signed-in and unauthorized callable. No unrelated business features.

**Exit:** both app and emulator start; checks pass; no secret; architecture & ADR written.

## PHASE 1 — Auth + household + accounts
Implement F01–F10 per `05_FUNCTIONS_CATALOG`; UI-01..04, 26–28, 38–40; Google/Apple auth adapters + phone auth capability flags; first personal household; CRUD accounts/categories; invites, member roles, leaving/removing; tenant-scoped RTDB projections; rules and full membership tests. Build A01-A24 shared UI components and reusable navigation. Member removal purges local protected state. No fake email/SMS sending if credentials unavailable.

**Exit:** TC-001..003, TC-035 pass in emulators; golden Home shell; multi-tenant deny proven.

## PHASE 2 — Immutable ledger, projections, budgets, reports
Implement F11–F17 and F41, plus F47–F48 (manually entered bill due and settlement). Build pure `Money`, PostingEngine, event canonical transaction with deterministic ID+fingerprint, command outbox, projector, reconciliation and idempotent summary. Screens UI-09..14, UI-20..25 and Home metrics. For transfers show impact only on accounts, not spend/income. Error/offline/pending vs posted UX. Use `Asia/Ho_Chi_Minh` for fixture tests. Run concurrency + replay invariants at 1000 events, verify outputs from canonical ledger.

**Exit:** TC-004..010, 014..017, 030, 031, 037 pass; zero double posting/mismatches.

## PHASE 3 — Wealth / Savings / Investment
Implement F18–F25 and F49 (liabilities) with asset, valuation, liabilities, holdings, contributions, savings goals, net worth and quarterly/yearly growth. Screens UI-29..34; charts with exact labels and `NO_DATA` state. Do not invent security quote integrations. Mark estimates/stale/manual sources. Ensure no double counting account balances and manually entered related assets. Explain XIRR/TWR selection in docs and tests.

**Exit:** TC-018..020 pass, asset/liability unit suite and accessible chart alternatives complete.

## PHASE 4 — Receipt camera/OCR/private Storage
Implement F26–F29 plus F53 (secure receipt preview) with private path reservations, short-lived signed upload, cloud finalize validation, Tasks, OCR adapter and normalization. Use a Vietnamese-capable OCR provider with benchmark under flags; Document AI Expense Parser is not assumed Vietnamese supported. Camera/gallery/crop/progress/review/error/manual screens UI-15..19. User confirmation once-only; client can correct low-confidence fields; retry safe. PII not in logs; deletion retention implemented.

**Exit:** TC-011..013/036 pass, 2-device concurrent confirms produce exactly one event; failure to manual tested.

## PHASE 5 — Widgets & Push Notifications
Implement F30–F36 plus F50 (mark notification read), per-user widget layouts with revision CAS and 9 registry types, in-app drag editor and gallery, server-safe snapshot, FCM/APNs setup, inbox/settings/quiet hours/deep link. Native WidgetKit/Glance behind separate feature flag with redacted snapshots; no full numbers on lockscreen by default. Notifications never duplicate inbox when event task replays. Use UI-05..08, 35..37.

**Exit:** TC-021..024 and TC-040 pass, native widget demo works on real test devices if signing available, otherwise explicitly blocked.

## PHASE 6 — Mây Plus & Free Ads
Implement F37–F40 and store verification adapters. Paywall UX UI-41..44: simple monthly/annual selected, target 19k/190k VND, but actual purchase price from store. Apple signed server Notifications V2 and Google RTDN validate webhook/identity then fetch authoritative status; dedupe, reconcile, handle pending/grace/refund/restore. Only verified `noAds` prevents ads. Integrate AdMob safe placements and UMP/ATT consent. Free app retains finance core. Never use Stripe/card form for mobile digital purchases by default; no fake successful billing.

**Exit:** TC-025..029, 038/039 pass with emulator mocks plus store sandbox when credentials available; document which succeeded.

## PHASE 7 — Privacy export/delete, release and observability
Implement F42–F45, secure export/delete, backups/reconciliation, audit logs, incident runbooks, consent/legal placeholder wiring, crash/perf monitoring redacted, budget/cost alerts. Validate all 48 UI routes, all 53 handler specs, every RTDB read rule, RPO/RTO, accessibility 200% text/reduce motion, Android/iOS release builds, Store review checklist. Do NOT publish without owner approval.

**Exit:** complete TC-001..044, zero P0 blockers or explicit go/no-go; release report with exact tests/screenshots/log redaction.

## Review / hardening prompt (use after any phase)
Act as an independent adversarial reviewer of the just-written Mây code. List precise security, money/rounding, concurrency, RBAC, privacy, provider callbacks, UX accessibility and resource-cost defects with affected file/line. Add failing tests reproducing each high-severity issue before fixing; re-run checks; never state success without evidence. Prioritize critical financial correctness and tenant isolation over style refactors.

## Refactoring and cost optimization prompt
Profile RTDB connection/egress and Cloud Functions cold starts, OCR cost, FCM fanout, widget refresh load, and client rendering. Identify N+1 reads, unnecessary RTDB root listeners, repeated OCR, hot key writes, and unbounded retries. Propose and implement measured optimizations while preserving event invariants and privacy. Provide before/after benchmark methodology and results; don't invent performance numbers.
