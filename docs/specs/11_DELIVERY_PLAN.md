# 11 — Delivery Plan, Dependencies, Milestones & Operations

## Teams/roles (small startup team)
- **Mobile lead (Flutter):** app shell, tokens, state, widgets, screens, E2E.
- **Backend lead (TypeScript/Firebase):** command APIs, ledger, projections, RTDB rules, reliability.
- **Product/UX:** prototype alignment, content, Figma semantics, accessibility, user testing.
- **QA/SRE/security:** Emulator rules, concurrency and store test, CI/CD, monitoring, privacy.
One engineer/agent may cover multiple roles but code review for ledger, billing, security must be independent before release.

## Milestone 0 — Repository, decisions and toolchain
**Dependencies:** Firebase project dev/staging/prod and bundle IDs owner-configured, Apple/Google console accounts at correct stage.
- Create monorepo, Flutter stable pinned, Firebase Functions TypeScript strict, contracts package, lint/format, git hooks, `.env.example` without secrets.
- Implement emulator suite, CI GitHub Actions `validate`, private config via Secret Manager and GitHub environment protections.
- Add architectural ADR + threat review + provider account checklist.
- **Done:** Flutter app launch and Functions HelloWorld in emulators, test pipeline green, no secrets in repo.

## Milestone 1 — Auth, household, design system
- Build 24 UI foundation components and navigation shell, Vietnamese localization, light/dark, responsive.
- Auth Google/Apple/phone adapters; first-login personal household; invitation and role rules; membership cache clear.
- F01–F10, F46, F51–F52 and hardened RTDB rules for user/household/accounts/categories.
- **Done:** first-use flow, invite accepted, other tenant inaccessible in emulator; golden screens.

## Milestone 2 — Financial ledger & analytics (hardest, mandatory before UI polish)
- Build immutable ledger domain, postings for income, expense, transfers and reversals/corrections; command outbox; idempotency; period calculator.
- F11–F17, F41, F47–F48; projection/reconciliation jobs, account balances and category/month/weekly/yearly reporting.
- UI Transaction List/Create/Detail/Transfer/Correction, Home totals, budget create/list/alert.
- **Done:** TC-004..018 and TC-037 pass; dashboard numbers equal independent canonical sum after replay.

## Milestone 3 — Wealth / savings / growth
- F18–F25 plus F49, accounts, net worth, liabilities, holdings, manual valuations, savings goals.
- Implement cashflow-aware return methodology or display NO_DATA explicitly; growth threshold push only with enough information.
- UI wealth/assets/holding/goal flows, history with source and freshness.
- **Done:** duplicated asset exclusion, contribution != profit, insufficient valuation no alert.

## Milestone 4 — Receipt capture & OCR integration
- F26–F29 plus F53, Storage Rules, OCR adapters, normalization/confidence and manual fallback, queue/cost caps, retention.
- UI camera/upload/crop/progress/review/edit/manual error; OCR benchmarking with Vietnamese receipt fixtures and privacy review.
- **Done:** unreviewed receipts never post; 2-device confirm creates one event; cost/error telemetry working.

## Milestone 5 — Widgets, notifications & privacy
- F30–F36 plus F50; edit/layout persistence, in-app widget registry, inbox/quiet hours/deep links, FCM/APNs.
- WidgetKit and Android Glance optional separate release flag if platform experience not ready; must not block base launch.
- **Done:** widget personalization persists, no lock-screen data leak, push dedupe and quiet-hours tests pass.

## Milestone 6 — Monetization & compliance
- App Store/Google Play SKUs, native IAP purchase flow, signed webhooks F37–F40, store sandbox/refund/grace/restore.
- AdMob/UMP/ATT with privacy/legal review, Free ad placements, backend `noAds` entitlement controls.
- **Done:** Plus purchase hides ads only when store verified; revoke restores ad eligibility; no fake price; Free retains core.

## Milestone 7 — Reliability, go-live
- F42–F45, data export/delete, complete Security Rules/Storage Rules and privacy notices, monitor dashboards, cost limits, backups and restore drill.
- Performance on midrange Android and 3 iPhone form factors; disabled network/retry scenarios, store TestFlight/Internal Test, closed beta user feedback.
- **Done:** all P0 acceptance, leak/permission testing, app store review requirements and go/no-go checklist.

## Prioritized backlog artifacts
For every task issue: `ID`, user story, route(s), functions IDs, RTDB paths, DTO, data rules, acceptance tests, feature flag, observability, risk, owner, PR link. Keep horizontal PRs small enough for review. Example:
```
MAY-FIN-021 / Implement manual expense
Depends: Auth household + categories/accounts + ledger API
Routes: UI-11, UI-13; Functions: F11, F14; Paths: ledgerEvents, transactionList, summaries
Acceptance: TC-004/005/006; a11y; analytics event expense_post_succeeded without amount
Rollout: RemoteConfig finance.manualExpense=true in dev only until passed
```

## CI/CD (GitOps-ish)
- Feature branch -> PR mandatory -> lint/typecheck/unit/emulator/static scans/golden -> signed build preview -> staging deploy -> smoke.
- Protected `main` with reviews. Staging secrets and signed app builds separate from prod.
- Prod backends deploy via approved GitHub environments; Firebase deploy subsets by function group (limit blast radius); schema migration additive with projection version.
- Android Play Internal → Closed → production staged rollout. iOS TestFlight → App Store phased release if available. Track crash-free and billing webhook errors; rollback client and functions separately.
- Remote Config kill switches only for non-critical features; never use for security decisions or fake payments.

## Infrastructure management
- One Firebase project per environment. Separate RTDB/Storage buckets/FCM identities; least privilege roles; budgets/quotas and logs set for each environment.
- Store signing keys, Apple App Store API key, Google publisher service credentials in secret manager; rotate/deactivate with runbook.
- Backup RTDB and Storage exports; daily status/incident review, monthly cost projection, restore rehearsal, retention cleanup.
- Region choices have latency, costs and compliance trade-offs; verify per-product available locations and use same geography where possible.

## Team merge gates
Money/postings, Security Rules and billing code require 2 reviewers (or 1 independent human reviewer for solo agent implementation). No automated agent should release to prod without explicit human approval for IAM, store purchases, legal texts, ads and data deletion.

## Product roadmap beyond v1
CSV bank import with user verification; recurring transactions; shared budget approval; optional bank aggregation under local contract; FX snapshots; licensed holdings quotes; web admin panel. Each is an ADR and new privacy/security threat review rather than silent scope creep.
