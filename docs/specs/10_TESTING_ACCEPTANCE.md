# 10 — QA Strategy, Test Matrix, Release Gates

## Test layers
1. **Dart domain unit**: Money, currency exponent, percent basis points, period timezone, net worth, return calculation, conflict handling.
2. **TypeScript service unit**: schema validation, RBAC, postings, idempotency, OCR normalizer, purchase state transitions, notification dedupe.
3. **Firebase Emulator integration**: Realtime DB rules, callable Auth/App Check fakes, Storage policies, event trigger replay, job state.
4. **Contract tests**: TS schema vs Dart models, function request/response/error snapshots, migration compatibility.
5. **Flutter widget/golden**: all screens light/dark, 3 device sizes, dynamic font scaling, semantic labels.
6. **E2E**: sign in/test provider, setup household, input flows, budgets, assets, OCR failure fallback, ads VIP flow in store sandbox.
7. **Security**: signed provider callbacks, cross-household access, privilege escalation, malformed media, throttling, caches.
8. **Load/resilience**: parallel writes, RTDB connection fanout, offline resubmission, projector delays, retries, stale store/FCM.

## Acceptance scenarios (minimum)
| Test ID | Requirement | Setup | Action | Expected |
|---|---|---|---|---|
| TC-001 | FR-001/002 | new UID | first sign-in repeated | 1 personal household, 1 owner membership |
| TC-002 | FR-003/004 | owner+viewer | viewer invites member | permission denied |
| TC-003 | FR-004 | removed member | read household data | denied immediately, cache purged |
| TC-004 | FR-007 | normal expense | submit valid | 1 immutable ledger event |
| TC-005 | FR-007 | retry same key 5x | repeated callable | same event ID, one expense |
| TC-006 | FR-007 | same id diff amount | repeat | DUPLICATE_CONFLICT, no added posting |
| TC-007 | FR-008 | two cash accounts | transfer 500k | balances -500k/+500k, income=expense=0 |
| TC-008 | FR-009 | posted expense | reverse once + retry | exactly one reversal, total restored |
| TC-009 | FR-009 | posted expense | correct amount 185k→180k | audit events intact; net expense 180k |
| TC-010 | FR-010 | 14 months data | query current page | only bounded month-shard events downloaded |
| TC-011 | FR-012/013 | image with uncertain total | OCR | marked needs review, zero auto events |
| TC-012 | FR-013 | receipt confirmation | two devices submit in parallel | one ledger event tied to job |
| TC-013 | FR-013 | OCR timeout | retry → manual | retains fields, can save manually |
| TC-014 | FR-014 | 4.5M budget | expense crosses 80% | 1 inbox alert and optional push |
| TC-015 | FR-015 | same threshold | webhook/task replay | no second inbox alert |
| TC-016 | FR-018 | month boundary timezone | transact near midnight | correct Asia/Ho_Chi_Minh period |
| TC-017 | FR-019 | reversed transfer | report category | transfer excluded, reversal net properly |
| TC-018 | FR-021 | bank 5M linked to asset | net worth | not counted twice |
| TC-019 | FR-023/024 | investment + deposits | calculate growth | contribution not called profit |
| TC-020 | FR-024 | absent start valuation | growth alert check | status NO_DATA, no misleading push |
| TC-021 | FR-016/017 | widget edit | drag/hide, restart | saved order and visibility |
| TC-022 | FR-027 | OS widget privacy ON | lock screen | no financial amount leaked |
| TC-023 | FR-025/026 | push tap | deep link archived item | safe fallback not crash/IDOR |
| TC-024 | FR-026 | quiet hours 22–07 | budget 23h | inbox now, push deferred/suppressed |
| TC-025 | FR-029 | Free user | open Home | only safe ad placement |
| TC-026 | FR-029/030 | Plus verified | activate membership | ads unloaded, content reflows |
| TC-027 | FR-030 | fake purchase token | verifyStorePurchase | no entitlement |
| TC-028 | FR-030 | valid store purchase | refund webhook replay | entitlement revoked once |
| TC-029 | FR-030 | renewal webhook missed | scheduled reconcile | entitlement recovers state correctly |
| TC-030 | FR-031 | mixed VND/USD accounts | summary | no invalid silent conversion |
| TC-031 | FR-032 | phone offline | create expense | queued indicator, not posted until ack |
| TC-032 | FR-033 | non-owner | household export | denied, no file created |
| TC-033 | FR-034 | member in shared household | delete own account | preserve shared records per policy |
| TC-034 | FR-035 | 200% text scale | all key screens | no clipping of primary CTAs |
| TC-035 | FR-001/004 | UID A in household A | read household B | denied in RTDB rule and functions |
| TC-036 | FR-012 | oversized malicious file | upload | Storage reject before OCR queue |
| TC-037 | FR-007 | 1000 events + retries | projection rebuild | exactly same canonical totals |
| TC-038 | FR-028 | no ad consent | app load | no non-compliant ad request |
| TC-039 | FR-030 | store price ≠ target mock | paywall | display actual localized store price |
| TC-040 | FR-035 | reduce motion ON | drag/edit/route | no unnecessary animation, still usable |
| TC-041 | FR-037 | bill with linked expense | mark settlement twice | one payment linkage, no duplicate expense |
| TC-042 | FR-038 | other UID notification | mark read | denied, no leak |
| TC-043 | FR-039 | owner transfer pending | target accepts then previous owner loses special powers | one authoritative owner and legal access preserved |
| TC-044 | FR-011 | receipt owner removed | request signed preview | denied, no URL minted |

## Focused financial correctness suite
- Property based `sum(postings.deltaMinor)=0` every event; type EXPENSE/INCOME/TRANSFER invariants.
- Amount boundary `0`, `-1`, MAX_SAFE_INTEGER, Infinity/NaN from decoded payload, unsupported currency, malformed decimals.
- Duplicate request same payload exactly same output; duplicate key modified payload consistent conflict.
- Reversals/corrections preserving event provenance; totals reflect net effect not old/extra entry.
- 500 parallel posts same account; reconcile canonical balance (no lost increment), deterministic eventual projection.
- Projection trigger delivered twice/out-of-order/restarted; no double count; orphan checkpoint repaired.
- Budget threshold entry→reversal→entry and backdated expense; define re-alert policy (once/period/threshold).
- Net worth test cash + deposit + card liability + house estimate + holding linked account; no double count.
- User-entered holdings with contributions/withdrawals/fees: return algorithm tested against independent library or spreadsheet reference; absent price returns NO_DATA.

## Build gates (blocking)
| Gate | Target |
|---|---|
| Dart format/analyze | zero warnings/errors on required checks |
| Functions TypeScript strict typecheck/lint | pass |
| Unit + Emulator suites | all P0 tests pass |
| Cross-tenant rules | no unauthorized read/write in matrix |
| Ledger invariant | zero violations |
| Concurrency replay | no duplicate/amount mismatch |
| Store sandbox | purchase, renew, cancel, refund, restore, grace tested |
| OCR | benchmark reviewed, manual fallback, user review enforced |
| Accessibility | screen readers, 200% font, reduce motion |
| Secrets/license scan | no secrets/licenses blocking release |
| Backups | latest staging restore verified |
| Budget/cost alert | monitoring active before prod rollout |

## Test environment & fixtures
- Firebase emulators for Auth, RTDB, Storage, Functions. Use fake Clock, OCR adapter, FCM transport, billing verifier; never hit paid API in default CI.
- Fixed test tenant `hh_alpha`, second tenant `hh_beta`, roles OWNER/ADMIN/EDITOR/VIEWER, invalid/no membership; synthetic data, never real receipt images.
- Component golden tests for each screen at narrow/wide with light/dark + 200% font; screenshot baseline reviewed before updates.
- E2E store sandbox and Apple TestFlight / Play Internal Testing kept separate from local unit tests; platform signing required.

## Observability / incident testing
- Trigger controlled OCR quota failure, FCM unavailable, RTDB read-only, store webhook delay, expired auth token, app downgrade, malicious invite.
- Verify user-visible error, trace correlation without financial PII, auto-retry and recovery after service restoration.
- Run `reconcileFinancialProjections(dryRun=true)` before release; mismatch must be 0 or investigated.

## Definition of Done (each feature)
Implementation + UI/empty/loading/error/offline states + server auth/validation + database rules + event logs redacted + tests + error mapping + docs + relevant metrics + accessibility check; release flag off until P0 acceptance passes.
