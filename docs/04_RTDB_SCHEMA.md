# 04 — Realtime Database Schema & Data Model

## 1. General conventions
- Canonical root paths are **flat**. Do not place all tenants below `/households/{hid}` to avoid reading huge subtrees.
- IDs generated UUID v4/ULID, allowed Firebase path keys (`.` `#` `$` `[` `]` `/` forbidden); use opaque unguessable invite IDs.
- `schemaVersion`, `createdAtMs`, `updatedAtMs` on mutable server-owned records; canonical events only `createdAtMs`.
- Money integer `amountMinor`/`currency` stored as safe JS integer; VND exponent 0, USD exponent 2. Never `float` for money, FX or securities quantity; use decimal **string** for fractional quantities/FX.
- Server-side function never trusts supplied `role`, `uid`, or computed totals; UID from auth, server reads role.
- RTDB Security Rules are not filters. Tenant auth at path + restricted paginated queries on large lists.
- Server SDK can bypass rules: authorization and schema validation **must also run in handlers**.

## 2. Canonical root-path dictionary
| Path | Cardinality/keys | Primary fields | Read | Write |
|---|---|---|---|---|
| `/users/{uid}` | 1/user | displayName, locale, defaultHouseholdId | self | functions |
| `/userHouseholds/{uid}/{hid}` | N/user | displayName, roleHint, active | self | functions |
| `/households/{hid}` | 1/tenant | name, currency, timezone, ownerUid | member | functions |
| `/members/{hid}/{uid}` | N/tenant | role, status, joinedAtMs | member | functions |
| `/invites/{id}` | N/tenant | householdId, role, expiresAtMs, tokenHash | server | functions |
| `/accounts/{hid}/{id}` | N/tenant | name, type, currency, openingBalanceMinor, archived | member | functions |
| `/categories/{hid}/{id}` | N/tenant | name, kind, icon, archived, sortOrder | member | functions |
| `/ledgerEvents/{hid}/{eventId}` | unbounded | kind, postings, fingerprint, actorUid, occurredAtMs, createdAtMs | **individual ID only** | append-only functions |
| `/ledgerOperations/{hid}/{opId}` | N/tenant | status, eventIds, attempt, lease | owner/admin (redacted) | functions |
| `/transactionList/{hid}/{YYYYMM}/{eventId}` | month shards | summary, amount, occurredAtMs, active | member with page-limit | projector |
| `/accountMovements/{hid}/{accountId}/{YYYYMM}/{eventId}` | account shards | deltaMinor, occurredAtMs, sourceEventId | member | projector |
| `/balanceSnapshots/{hid}/{accountId}/{YYYYMM}` | by period | closingMinor, projectionVersion, asOfMs | member | projector |
| `/summaries/{hid}/{YYYYMM}` | by period | incomeMinor, expenseMinor, byCategory, builtAt | member | projector |
| `/bills/{hid}/{billId}` | N/tenant | title, dueAtMs, amountMinor?, status, linkedLedgerEventId? | member | functions |
| `/ownershipTransferRequests/{requestId}` | N/tenant | householdId, fromUid, toUid, expiresAtMs, status | server/target via callable | functions |
| `/budgets/{hid}/{budgetId}` | N/tenant | categoryIds, limitMinor, period, thresholds | member | functions |
| `/budgetStatus/{hid}/{budgetId}/{periodKey}` | N/budget | usedMinor, triggeredThresholdIds, computedAt | member | projector |
| `/assets/{hid}/{assetId}` | N/tenant | kind, name, includedInNetWorth, linkedAccountId | member | functions |
| `/assetValuations/{hid}/{assetId}/{valueId}` | N/asset | amountMinor, asOfMs, source, estimated | member | functions |
| `/liabilities/{hid}/{id}` | N/tenant | balanceMinor, type, source, asOfMs | member | functions |
| `/investmentHoldings/{hid}/{id}` | N/tenant | symbolOrName, quantityDecimal, costBasisMinor | member | functions |
| `/investmentCashflows/{hid}/{holdingId}/{flowId}` | N/holding | type, amountMinor, asOfMs | member | functions |
| `/goals/{hid}/{goalId}` | N/tenant | targetMinor, linkedAccountIds, dueAtMs | member | functions |
| `/netWorthSnapshots/{hid}/{YYYYMM}` | monthly | assetTotal, liabilityTotal, netWorth, sources | member | projector |
| `/growthInsights/{hid}/{period}` | quarterly/yearly | method, returnBps, status, confidence, sources | member | projector |
| `/receiptJobs/{hid}/{jobId}` | N/tenant | createdByUid, state, objectPath, provider, errorCode | member/creator policy | functions |
| `/receiptDrafts/{hid}/{jobId}` | 1/job | merchant, date, items, total, confidence, userReviewed | member/creator | functions |
| `/notificationInbox/{uid}/{id}` | N/user | type, title, bodySafe, target, readAtMs | self | functions |
| `/notificationRead/{uid}/{id}` | N/user | mark-read timestamp, harmless personal state | self | own UID with restrictive rule |
| `/notificationSettings/{uid}` | 1/user | optInTypes, quietHours, redactAmounts | self | callable/direct validated |
| `/deviceTokens/{uid}/{deviceId}` | N/user | tokenHash, encryptedToken, platform, updatedAt | server only | functions |
| `/widgetLayouts/{hid}/{uid}` | 1/member/household | version, items, updatedAt | self | callable/direct validated |
| `/widgetSnapshots/{uid}/{hid}` | 1/member/household | safeMetrics, redacted, asOfMs, ttlMs | self | functions |
| `/entitlements/{uid}` | 1/user | plan, noAds, provider, validUntilMs | self | verified billing only |
| `/purchaseEvents/{provider}/{eventId}` | unbounded/time-window | payloadHash, processedAt, outcome | server only | billing handler |
| `/projectionCheckpoints/{hid}/{partition}` | N/tenant | lastEvent, version, rebuiltAt | server only | projector |
| `/idempotency/{hid}/{uid}/{requestId}` | N/user | fingerprint, result, createdAt | server only | functions |
| `/auditLogs/{hid}/{auditId}` | N/tenant | actor, action, result, time, corrId | owner/admin if policy | functions |
| `/exportJobs/{uid}/{jobId}` | N/user | state, expiresAt, objectPath | self | functions |
| `/deletionJobs/{uid}/{jobId}` | N/user | state, scope, requestedAt | self | functions |

`notificationInbox` and `purchaseEvents` must not expose merchant/amount raw, receipt OCR PII or billing JWS. Native widget snapshots contain only allowlisted fields + privacy flag.

## 3. Example nodes
### Household
```json
{
  "households": {
    "hh_01": {
      "schemaVersion": 1,
      "name": "Gia đình",
      "ownerUid": "uid_owner",
      "currency": "VND",
      "timezone": "Asia/Ho_Chi_Minh",
      "createdAtMs": 1792440000000
    }
  },
  "members": {
    "hh_01": {
      "uid_owner": { "role": "OWNER", "status": "ACTIVE", "joinedAtMs": 1792440000000 }
    }
  }
}
```

### Account
```json
{
  "id": "acc_cash",
  "type": "CASH",
  "name": "Tiền mặt",
  "currency": "VND",
  "openingBalanceMinor": 2000000,
  "openingAtMs": 1792440000000,
  "archived": false,
  "createdByUid": "uid_owner",
  "schemaVersion": 1
}
```
### Canonical LedgerEvent — EXPENSE
```json
{
  "eventId": "evt_01",
  "clientRequestId": "req_01",
  "fingerprint": "sha256:canonical-payload-example",
  "schemaVersion": 1,
  "kind": "EXPENSE",
  "currency": "VND",
  "amountMinor": 185000,
  "accountId": "acc_cash",
  "categoryId": "cat_food",
  "merchant": "Siêu thị",
  "occurredAtMs": 1792440000000,
  "createdAtMs": 1792440066000,
  "actorUid": "uid_owner",
  "postings": {
    "asset_cash": { "ledgerAccount": "ASSET:acc_cash", "deltaMinor": -185000 },
    "expense_food": { "ledgerAccount": "EXPENSE:cat_food", "deltaMinor": 185000 }
  }
}
```
### TRANSFER / reversal
- Transfer `acc_bank -> acc_cash`: `ASSET:acc_bank: -500000`, `ASSET:acc_cash: +500000`, postings sum zero, type TRANSFER. No category expense.
- Reversal references target: `reversesEventId=evt_01`, inverse postings, `kind=REVERSAL`, `correctsEventId` optional; aggregate calculators ignore net reversal/correction duplicate effects.

### ReceiptJob state
`CREATED -> UPLOADED -> QUEUED -> PROCESSING -> REVIEW_REQUIRED -> CONFIRMED` or `FAILED/EXPIRED/DISCARDED`. `CONFIRMED` requires accepted ledger event. Storage path: `receipts/{hid}/{uid}/{jobId}/original.jpg`, max file limits and MIME enforced by backend + Storage Rules. Avoid public getDownloadURL stored unbounded.

### Budget / user settings
```json
{
  "budgets": {
    "hh_01": { "b_food": { "categoryIds": { "cat_food": true }, "period": "MONTH", "limitMinor": 4500000, "currency": "VND", "thresholdBps": [8000, 10000], "enabled": true } }
  },
  "notificationSettings": {
    "uid_owner": { "enabled": true, "types": { "BUDGET": true, "BILL_DUE": true, "GROWTH": false, "WEEKLY": false }, "quietHours": { "enabled": true, "start": "22:00", "end": "07:00", "timezone": "Asia/Ho_Chi_Minh" }, "redactAmounts": true }
  }
}
```

### Mây Plus entitlement
```json
{
  "entitlements": {
    "uid_owner": {
      "plan": "PLUS_MONTHLY",
      "noAds": true,
      "provider": "APPLE",
      "storeProductId": "may.plus.monthly",
      "state": "ACTIVE",
      "validUntilMs": 1795000000000,
      "lastVerifiedAtMs": 1792500000000
    }
  }
}
```
Only billing service writes; product ID and validity must come from cryptographically/provider-verified purchase, never client `plan:PLUS`.

## 4. Queries/indexes and pagination
- `/transactionList/{hid}/{YYYYMM}`: `.indexOn=["occurredAtMs"]`; `orderByChild('occurredAtMs').limitToLast(30)`, page by `(occurredAtMs,eventId)` stable cursor; Firebase tie-break details must be tested. Limit and restrict path reads in rules; month-chunk retrieval.
- `/accountMovements/{hid}/{accountId}/{YYYYMM}` `.indexOn=["occurredAtMs"]`, similar cursor.
- `/notificationInbox/{uid}` `.indexOn=["createdAtMs"]`, separate unread marker/read model to avoid expensive query; status scan bounded.
- `/assetValuations/{hid}/{assetId}` `.indexOn=["asOfMs"]`.
- `/investmentCashflows/{hid}/{holdingId}` `.indexOn=["asOfMs"]`.
- Avoid `orderByChild` across all tenants or fetching root; no server-side aggregation in RTDB query; compute projection server-side.
- Parent `.read` rule can override child restrictions: no permissive grants at ancestor paths. Explicitly test permissions on every nested path.

## 5. Event / projection invariants
- All postings for a single currency sum to zero.
- No second posting of same idempotency key and same UID in a tenant.
- Every projected movement has a canonical `sourceEventId`.
- Account balance = opening + sum(active asset postings), with reversal included; rounding 0 for VND.
- Expense budget metric includes posted expense categories minus corresponding reversals; excludes transfers.
- Total monthly expense = sum(visible category totals), sign normalized for UI.
- Net worth = assets - liabilities; excludes internal representations double counting.
- Failed projection does not change original immutable ledger; run `reconcileFinancialProjections` to rebuild.

## 6. Data lifecycle
- Mutable settings: last-write-wins only for harmless preference fields, use `revision` CAS for widget layout on concurrent devices.
- Ledger canonical events: no soft-delete mutation. Account deletion uses policy-based anonymization/retention workflow; not physically erase audit history prematurely where legally required.
- Receipts: original image retention default 90d unless saved explicitly; extracted drafts expire 30d after unconfirmed; final transaction minimal linked metadata.
- Tokens: FCM rotation immediate; purge invalid tokens on provider errors.
- Expired invitation cleanup every day. Store event replay history and billing evidence according to fraud/accounting/legal retention review.
- User deletion/export must consider other household co-owners: do not erase shared ledger silently; provide household transfer/export or anonymized authorship.

## 7. Migration/versioning
- `schemaVersion` per record; schema changes additive. Projector `projectionVersion` per partition.
- On change in aggregation logic, run versioned rebuild in staging/prod shadow namespace, compare totals, flip reader via Remote Config, remove old only after validation.
- Backup/export and restore tests are release gates. Monitor RTDB size, concurrent connections, bandwidth and per-path hot spots.

## 8. Strong consistency caveat
RTDB atomic multipath `update()` guarantees write fan-out all-or-nothing but is **not** an optimistic transaction across separately changing nodes. The canonical create-at-event-key transaction is unique and safe for household tracking, while aggregate reads are eventually consistent. Do not claim this architecture satisfies regulated banking-level double-entry ACID guarantees. If Mây expands to true asset movement or high-concurrency shared accounting, plan a canonical ledger migration to PostgreSQL or another transactional engine.
