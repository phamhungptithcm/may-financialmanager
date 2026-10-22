# Mây Family Finance — Cloud Functions contract inventory

TypeScript Cloud Functions v2. Callable operations require auth, App Check, runtime validation, entitlement if relevant, RBAC, correlationId; `clientRequestId` (UUID) required for mutating money flows. Use `onCall`, `onValueCreated`, `onSchedule`, `onRequest`, and Pub/Sub where appropriate.

**Legend:** C = callable; E = event trigger; S = scheduled; H = authenticated provider webhook / PubSub. P0 = core MVP, P1 = enhanced, P2 = later.

| ID | Export / service | Type | Priority | Contract / responsibility |
|---|---|---|---|---|
| F01 | `bootstrapProfile` | C | P0 | auth → uid profile, default locale |
| F02 | `createHousehold` | C | P0 | `{name,currency,timezone}` → hid, owner membership |
| F03 | `updateHousehold` | C | P0 | owner/admin updates name/timezone with version check |
| F04 | `inviteHouseholdMember` | C | P0 | `{hid, target, role}` → opaque one-use invite, expiry |
| F05 | `acceptHouseholdInvite` | C | P0 | `{inviteToken}` → new member; server verifies token/expiry |
| F06 | `changeHouseholdRole` | C | P0 | owner/admin permissions, no last-owner removal |
| F07 | `removeHouseholdMember` | C | P0 | revoke membership, device access invalidation |
| F08 | `createFinancialAccount` | C | P0 | `{hid,name,type,currency,openingBalanceMinor}` → accountId |
| F09 | `updateFinancialAccount` | C | P0 | metadata/close account; no direct balance overwrite |
| F10 | `upsertCategory` | C | P0 | income/expense taxonomy, icon, parentId optional |
| F11 | `createLedgerEvent` | C | P0 | income/expense/transfer; canonical immutable event |
| F12 | `reverseLedgerEvent` | C | P0 | correcting event, not delete of canonical original |
| F13 | `onLedgerEventCreated` | E | P0 | fanout deterministic transactionList/movements, enqueue projector |
| F14 | `rebuildAccountProjection` | C/Admin task | P0 | reconstruct balances from canonical events, diagnostic |
| F15 | `buildPeriodSummary` | E/Task | P0 | recompute by month + category, stable snapshot version |
| F16 | `upsertBudget` | C | P0 | thresholds, period, category and scope |
| F17 | `evaluateBudgetThreshold` | E/Task | P0 | compare posted eligible spend vs limit; dedupe alerts |
| F18 | `createGoal` | C | P1 | savings and investment goals |
| F19 | `updateGoal` | C | P1 | target, due date, linkedAccountId |
| F20 | `upsertAsset` | C | P1 | property, vehicle, jewelry, etc.; no double counting |
| F21 | `recordAssetValuation` | C | P1 | amount, valuationAt, source, estimated flag |
| F22 | `upsertHolding` | C | P1 | investments metadata with data provenance |
| F23 | `recordInvestmentCashflow` | C | P1 | contribution/withdrawal/dividend, currency, date |
| F24 | `buildNetWorthSnapshot` | E/Task | P1 | accounts + valuations - liabilities |
| F25 | `evaluateGrowthGoal` | S | P1 | quarterly/yearly with cashflow-adjusted changes |
| F26 | `initReceiptUpload` | C | P1 | jobId, signed/guarded upload path, max size & type |
| F27 | `parseReceipt` | C/Task | P1 | OCR + field normalization + confidence and failure status |
| F28 | `confirmReceiptDraft` | C | P1 | reviewed draft → create ledger with idempotency |
| F29 | `discardReceiptDraft` | C | P1 | remove unconfirmed draft, schedule file deletion |
| F30 | `registerDeviceToken` | C | P1 | associate device+FCM token with UID, rotation |
| F31 | `updateNotificationSettings` | C | P1 | category flags, quiet hours, redaction |
| F32 | `dispatchNotification` | Task/E | P1 | persisted inbox + FCM, dedupe and retry |
| F33 | `sendBillDueReminders` | S | P1 | local date/time based billing reminders |
| F34 | `sendWeeklySummary` | S | P1 | user opt-in timezone/week interval |
| F35 | `publishWidgetSnapshot` | E/Task | P1 | small safe payload per user; native refresh hint |
| F36 | `saveWidgetLayout` | Direct RTDB / C | P1 | user-owned order, visibility and widget type validation |
| F37 | `verifyStorePurchase` | C | P2 | server-side store verification before entitlement |
| F38 | `handleAppStoreNotification` | H | P2 | signed App Store server notifications; replay-safe |
| F39 | `handleGooglePlayRtdn` | H | P2 | Pub/Sub verified event; check Play Developer API |
| F40 | `reconcileSubscriptionStatus` | S | P2 | expiry/refunds/grace/restore backfill |
| F41 | `reconcileFinancialProjections` | S | P0 | detect / repair mismatches, alert engineering |
| F42 | `pruneExpiredInvitesAndDrafts` | S | P1 | data retention + lifecycle |
| F43 | `exportHouseholdData` | C/Task | P2 | asynchronous ZIP/JSON/CSV export and auth scope |
| F44 | `deleteAccountData` | C/Task | P2 | verified sensitive deletion workflow + retention policy |
| F45 | `auditCriticalAction` | Internal | P0 | user/actor/type/time/correlation ID, no raw secrets |

## Suggested TS module folders
```
functions/src/
  index.ts                  # exports only
  config/{env,regions}.ts
  common/{auth,rules,errors,logger,idempotency,schemas}.ts
  household/{callables,service,repository}.ts
  ledger/{callables,postingEngine,projector,reconciliation}.ts
  budget/{callables,evaluator}.ts
  receipts/{callables,ocrProvider,normalizer}.ts
  assets/{callables,valuation,growth}.ts
  notifications/{callables,dispatcher,scheduler}.ts
  purchases/{callables,apple,google,entitlements}.ts
  widgets/{callables,snapshot}.ts
  maintenance/{export,erase,cleanup}.ts
```

## Example API shapes (type definitions, not full implementation)
```ts
type Currency = 'VND' | 'USD';
type IdempotentRequest = { householdId: string; clientRequestId: string };
type CreateExpense = IdempotentRequest & {
  kind: 'EXPENSE'; accountId: string; categoryId: string;
  amountMinor: number; currency: Currency; occurredAtMs: number;
  merchant?: string; note?: string; receiptJobId?: string;
};
type CreateTransfer = IdempotentRequest & {
  kind: 'TRANSFER'; fromAccountId: string; toAccountId: string;
  amountMinor: number; currency: Currency; occurredAtMs: number;
};
type CreateLedgerResponse = {
  eventId: string; status: 'CREATED' | 'EXISTS';
  projectionStatus: 'PENDING' | 'READY';
};
```

### Do not expose independent calls for every read
Authorized Flutter clients can subscribe to small RTDB projections directly (monthly summaries, one account, notification inbox, widget layout). Callable is reserved for validation/privileged business logic or expensive queries, avoiding avoidable Cloud Functions latency and cost.

### Async event consistency
Event triggers are at least once, not exactly once. For side effects: eventId-based idempotent writes to immutable movement paths; deterministic notification/outbox IDs; projector versioned snapshots and daily reconciliation. Never `balance += delta` on a trigger without an atomic dedupe mechanism on the same transaction node.
