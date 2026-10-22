# 05 — Function Catalog (53 handlers / jobs)

## Operating contract (EVERY function)
- Use TypeScript Firebase Functions v2. Callable handlers: enforce Firebase Auth, App Check where supported, validate strict Zod schema, read ACTIVE membership + role from trusted database. `auth.uid` not client-provided `uid`.
- `Admin SDK` bypasses RTDB Security Rules. Never omit server-side authorization.
- PII-safe structured logging only (`correlationId`, function, latency, outcome). Error response sanitized and stable.
- Monetary amount = finite safe positive integer minor unit, currency ISO code allowlist; zero-sum balanced postings; account/category/asset belongs to `householdId`.
- Side effects run only *after* auth + validation; external retryable calls via Cloud Tasks; idempotency prevents duplicate ledger events, alerts, purchase activation.
- Use module separation: `index` exports triggers only; `handler` validates; `service` business logic; `repository` RTDB; `mapper` DTO; dedicated unit tests.
- `C`=Callable, `T`=Task/RTDB event, `S`=Scheduled, `H`=HTTP/store webhook, `I`=internal. Functions listed include internal handlers, not 53 separately billed deployments. Deployment name must be stable across release.
- Standard errors: unauthenticated, permission-denied, invalid-argument, failed-precondition, already-exists, resource-exhausted, unavailable, internal; see API docs.

## Function summary

| # | Function | Trigger | Role | Output |
|---|---|---|---|---|
| F01 | `createHousehold` | callable | Authenticated user | householdId |
| F02 | `updateHousehold` | callable | OWNER,ADMIN | householdId |
| F03 | `inviteHouseholdMember` | callable | OWNER,ADMIN | inviteId |
| F04 | `acceptHouseholdInvite` | callable | Authenticated invitee | householdId |
| F05 | `changeHouseholdRole` | callable | OWNER,ADMIN restrictions | targetUid |
| F06 | `removeHouseholdMember` | callable | OWNER,ADMIN restrictions | removed:true |
| F07 | `leaveHousehold` | callable | Active member | left:true |
| F08 | `createAccount` | callable | OWNER,ADMIN,EDITOR | accountId |
| F09 | `updateAccount` | callable | OWNER,ADMIN,EDITOR | accountId |
| F10 | `upsertCategory` | callable | OWNER,ADMIN,EDITOR | categoryId |
| F11 | `createLedgerEvent` | callable | OWNER,ADMIN,EDITOR | eventId |
| F12 | `reverseLedgerEvent` | callable | OWNER,ADMIN,EDITOR | reversalEventId |
| F13 | `correctLedgerEvent` | callable | OWNER,ADMIN,EDITOR | operationId |
| F14 | `projectLedgerEvent` | RTDB trigger/task | Service account | projectionVersion |
| F15 | `buildAnalyticsSummary` | scheduled/task | Service account | summary |
| F16 | `upsertBudget` | callable | OWNER,ADMIN,EDITOR | budgetId |
| F17 | `evaluateBudgetThreshold` | event/task | Service account | usedMinor |
| F18 | `createGoal` | callable | OWNER,ADMIN,EDITOR | goalId |
| F19 | `updateGoal` | callable | OWNER,ADMIN,EDITOR | goalId |
| F20 | `upsertAsset` | callable | OWNER,ADMIN,EDITOR | assetId |
| F21 | `recordAssetValuation` | callable | OWNER,ADMIN,EDITOR | valuationId |
| F22 | `upsertHolding` | callable | OWNER,ADMIN,EDITOR | holdingId |
| F23 | `recordInvestmentCashflow` | callable | OWNER,ADMIN,EDITOR | flowId |
| F24 | `buildNetWorthSnapshot` | event/task | Service account | assetsMinor |
| F25 | `evaluateGrowthGoal` | scheduled/task | Service account | growthStatus |
| F26 | `initReceiptUpload` | callable | OWNER,ADMIN,EDITOR | jobId |
| F27 | `parseReceipt` | task | Service account | status |
| F28 | `confirmReceiptDraft` | callable | OWNER,ADMIN,EDITOR | eventId |
| F29 | `discardReceiptDraft` | callable | job creator,OWNER,ADMIN | discarded:true |
| F30 | `registerDeviceToken` | callable | Authenticated user | registered:true |
| F31 | `updateNotificationSettings` | callable | Authenticated user | settings |
| F32 | `dispatchNotification` | task | Service account | inboxId |
| F33 | `sendBillDueReminders` | scheduled | Service account | countSent |
| F34 | `sendWeeklySummary` | scheduled | Service account | countSent |
| F35 | `publishWidgetSnapshot` | event/task | Service account | snapshotVersion |
| F36 | `saveWidgetLayout` | callable | Authenticated active member | newRevision |
| F37 | `verifyStorePurchase` | callable | Authenticated user | entitlementState |
| F38 | `handleAppStoreNotification` | HTTPS webhook | Apple signed webhook | ackStatus |
| F39 | `handleGooglePlayRtdn` | PubSub event | Verified Google PubSub service | ackStatus |
| F40 | `reconcileSubscriptionStatus` | scheduled/task | Service account | countUpdated |
| F41 | `reconcileFinancialProjections` | scheduled/task | Service account | mismatchCount |
| F42 | `pruneExpiredInvitesAndDrafts` | scheduled | Service account | deletedCount |
| F43 | `exportHouseholdData` | callable/task | OWNER,ADMIN per scope | jobId |
| F44 | `deleteAccountData` | callable/task | Authenticated owner of data | jobId |
| F45 | `auditCriticalAction` | internal utility | Server handler only | auditId |
| F46 | `updateUserProfile` | callable | Authenticated user | uid |
| F47 | `upsertBill` | callable | OWNER,ADMIN,EDITOR | billId |
| F48 | `recordBillSettlement` | callable | OWNER,ADMIN,EDITOR | billId |
| F49 | `upsertLiability` | callable | OWNER,ADMIN,EDITOR | liabilityId |
| F50 | `markNotificationRead` | callable | Authenticated notification owner | notificationId |
| F51 | `initiateOwnershipTransfer` | callable | Current household owner | transferRequestId |
| F52 | `acceptOwnershipTransfer` | callable | Named target member | householdId |
| F53 | `getReceiptAccess` | callable | job creator or authorized member | signedGetUrl |

## Detailed implementation contracts

### F01 — `createHousehold`
- **Trigger / caller:** callable; authorized: Authenticated user.
- **Input / schema:** `name,timezone,currency,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `householdId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create household + OWNER membership + user index; initialize default categories.
- **Concurrency & retries:** dedupe by uid/requestId; transactional membership protection. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** reject invalid timezone/currency; duplicate onboarding creates one household. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F02 — `updateHousehold`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN.
- **Input / schema:** `householdId,name,optional timezone,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `householdId,revision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** update household metadata; rebuild report periods if policy changes.
- **Concurrency & retries:** revision compare-and-set. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** reject timezone mutation when historical events would be inconsistent without migration. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F03 — `inviteHouseholdMember`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN.
- **Input / schema:** `householdId,inviteRole,expiresInHours,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `inviteId,expiresAt,shareableLink`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create hashed single-use invite, audit.
- **Concurrency & retries:** dedupe requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** viewer cannot invite; cap invitations; no raw token logged. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F04 — `acceptHouseholdInvite`
- **Trigger / caller:** callable; authorized: Authenticated invitee.
- **Input / schema:** `inviteToken,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `householdId,role`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** validate hash expiry and single-use; write membership+userHousehold index.
- **Concurrency & retries:** token acceptance CAS + uid request id. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** expired/revoked/role changed, reused link, member already exists. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F05 — `changeHouseholdRole`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN restrictions.
- **Input / schema:** `householdId,targetUid,newRole,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `targetUid,newRole`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** update member + user index; audit.
- **Concurrency & retries:** revision CAS. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cannot demote last OWNER; admin cannot promote self to OWNER. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F06 — `removeHouseholdMember`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN restrictions.
- **Input / schema:** `householdId,targetUid,reason,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `removed:true`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** mark inactive; invalidate caches/access & FCM household subscriptions.
- **Concurrency & retries:** requestId, monotonic ACTIVE->REMOVED. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** member cannot remove last OWNER; all later reads denied. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F07 — `leaveHousehold`
- **Trigger / caller:** callable; authorized: Active member.
- **Input / schema:** `householdId,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `left:true`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** remove self membership/index, audit.
- **Concurrency & retries:** repeat leave returns success. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** last OWNER blocked unless transfer; no shared finance data destruction. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F08 — `createAccount`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,name,type,currency,openingBalanceMinor,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `accountId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write account metadata, establish opening balance.
- **Concurrency & retries:** stable clientRequestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** safe integers/currency; initial balance counted once. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F09 — `updateAccount`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,accountId,name,archived,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `accountId,revision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** change metadata, prohibit hard delete.
- **Concurrency & retries:** revision CAS. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cannot change currency/opening amount once ledger references exist without correction flow. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F10 — `upsertCategory`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,categoryId?,name,kind,icon,archived,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `categoryId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create/update category, keep historic reference.
- **Concurrency & retries:** idempotent upsert with revision. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** kind immutable if referenced; archived remains reportable. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F11 — `createLedgerEvent`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,clientRequestId,kind,accountId,categoryId?,amountMinor,currency,occurredAtMs,details`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `eventId,status:ACCEPTED`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write immutable balanced postings event, schedule projection.
- **Concurrency & retries:** deterministic event key + fingerprint compare. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** zero/negative or unsafe integer, invalid category, cross-household account, transfer net zero. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F12 — `reverseLedgerEvent`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,eventId,reason,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `reversalEventId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** reserve reversal once, create inverse immutable event, projection.
- **Concurrency & retries:** dedupe target reversal state + requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** double reversal rejected, amount sum invariant. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F13 — `correctLedgerEvent`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,eventId,replacementFields,reason,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `operationId,reverseId,newEventId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** orchestrate reversal plus corrected event with recoverable state machine.
- **Concurrency & retries:** durable operationId/step guard. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** partial failure resumes, never edit original, report totals reconciled. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F14 — `projectLedgerEvent`
- **Trigger / caller:** RTDB trigger/task; authorized: Service account.
- **Input / schema:** `householdId,eventId,projectionVersion`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `projectionVersion,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** update transaction list, account movement, summaries; schedule budgets.
- **Concurrency & retries:** deterministic partition/checkpoint and serial projector. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** duplicate/out-of-order trigger same totals; test parallel writes/replay. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F15 — `buildAnalyticsSummary`
- **Trigger / caller:** scheduled/task; authorized: Service account.
- **Input / schema:** `householdId,periodKey,force?,version`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `summary,asOfMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** rebuild period totals by category and account from canonical data.
- **Concurrency & retries:** replace deterministic projection for version. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** week/month/year timezone boundaries, transfer/reversal excluded. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F16 — `upsertBudget`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,budgetId?,categoryIds,limitMinor,period,thresholdBps,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `budgetId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write budget; trigger status refresh.
- **Concurrency & retries:** revision CAS or requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** category IDs belong to tenant, limit>0, thresholds sorted valid. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F17 — `evaluateBudgetThreshold`
- **Trigger / caller:** event/task; authorized: Service account.
- **Input / schema:** `householdId,budgetId,periodKey,eventId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `usedMinor,crossedThresholds`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** compute spend, deduped inbox alert trigger.
- **Concurrency & retries:** uid:hid:budget:period:threshold. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** alert once per threshold; reverse crossing and period rollover handled. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F18 — `createGoal`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,name,targetMinor,dueAtMs,linkedAccountIds,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `goalId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create savings/invest goal.
- **Concurrency & retries:** requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** target>0; due date; linked account tenant-check. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F19 — `updateGoal`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,goalId,patch,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `goalId,revision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** goal metadata update.
- **Concurrency & retries:** revision CAS. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** do not mutate historical growth data without recalculation. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F20 — `upsertAsset`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,assetId?,kind,name,includedInNetWorth,linkedAccountId?,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `assetId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write asset metadata.
- **Concurrency & retries:** requestId/revision. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** double counting check and valid linkage. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F21 — `recordAssetValuation`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,assetId,amountMinor,currency,asOfMs,source,estimated,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `valuationId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** append value point, enqueue net worth rebuild.
- **Concurrency & retries:** requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** stale/backdated valuation; asset exists; no silent overwrite. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F22 — `upsertHolding`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,holdingId?,name,quantityDecimal,costBasisMinor,currency,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `holdingId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write investment holding metadata.
- **Concurrency & retries:** requestId/revision. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** safe decimal string; no external market price assumed. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F23 — `recordInvestmentCashflow`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,holdingId,flowType,amountMinor,currency,asOfMs,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `flowId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** append CONTRIBUTION/WITHDRAWAL/DIVIDEND data; schedule growth.
- **Concurrency & retries:** requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cashflows distinct from return, sign and value range validation. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F24 — `buildNetWorthSnapshot`
- **Trigger / caller:** event/task; authorized: Service account.
- **Input / schema:** `householdId,asOfDate,projectionVersion`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `assetsMinor,liabilitiesMinor,netWorthMinor,staleAssets`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** combine unique asset IDs/liabilities, write snapshot.
- **Concurrency & retries:** deterministic period/version replacement. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** assets minus liabilities; linked accounts/holdings not double counted. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F25 — `evaluateGrowthGoal`
- **Trigger / caller:** scheduled/task; authorized: Service account.
- **Input / schema:** `householdId,period=QUARTER_or_YEAR,goalId?`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `growthStatus,returnBps?,confidence`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** derive return with external flows; compare user goal; create insight if reliable.
- **Concurrency & retries:** period:goal:method version. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** insufficient valuations/cashflows => NO_DATA not false warning. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F26 — `initReceiptUpload`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,fileName,mimeType,sizeBytes,sha256,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `jobId,storagePath,uploadPolicy`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** reserve receiptJob CREATED path and quotas.
- **Concurrency & retries:** requestId/fileHash short-term dedupe. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** disallow unsupported MIME, oversize/unsafe file, quota abuse. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F27 — `parseReceipt`
- **Trigger / caller:** task; authorized: Service account.
- **Input / schema:** `householdId,jobId,processorVersion`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `status,confidence,fieldCandidates`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** read Storage, detect language, OCR, normalize draft.
- **Concurrency & retries:** job:processorVersion deterministic processing. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** Vietnamese OCR fallback, errors/timeouts/PII restrictions. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F28 — `confirmReceiptDraft`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,jobId,reviewed:true,accountId,categoryId,totalMinor,currency,date,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `eventId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** transition draft to CONFIRMED bind ledger event once.
- **Concurrency & retries:** jobId CAS + requestId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** parallel confirms create one ledger event; rejected if no review. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F29 — `discardReceiptDraft`
- **Trigger / caller:** callable; authorized: job creator,OWNER,ADMIN.
- **Input / schema:** `householdId,jobId,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `discarded:true`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** mark DISCARDED and enqueue image cleanup.
- **Concurrency & retries:** monotonic terminal state. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cannot discard already confirmed and alter ledger. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F30 — `registerDeviceToken`
- **Trigger / caller:** callable; authorized: Authenticated user.
- **Input / schema:** `deviceId,platform,fcmToken,locale,appVersion`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `registered:true`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** store encrypted/restricted token, invalidate rotated token.
- **Concurrency & retries:** upsert by uid/deviceId. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cross-uid registration blocked, huge token rejected. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F31 — `updateNotificationSettings`
- **Trigger / caller:** callable; authorized: Authenticated user.
- **Input / schema:** `types,enabled,quietHours,redactAmounts,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `settings,revision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** save preferences per uid.
- **Concurrency & retries:** revision CAS. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** timezone and time validity; opt-out immediate. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F32 — `dispatchNotification`
- **Trigger / caller:** task; authorized: Service account.
- **Input / schema:** `uid,type,eventKey,target,titleTemplateId,variablesSafe`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `inboxId,deliveryState`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write safe inbox item and FCM push if opt-in.
- **Concurrency & retries:** deterministic inbox ID and send-outbox state. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** quiet hours/permission/invalid token/retries without inbox duplicate. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F33 — `sendBillDueReminders`
- **Trigger / caller:** scheduled; authorized: Service account.
- **Input / schema:** `runDate,tenantCursor`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `countSent`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** detect user-entered due items in local timezone, enqueue push.
- **Concurrency & retries:** billId:uid:dueDay:offset. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** do not repeat day reminder, no guessed due dates. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F34 — `sendWeeklySummary`
- **Trigger / caller:** scheduled; authorized: Service account.
- **Input / schema:** `runDate,tenantCursor`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `countSent`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** compose aggregate summary, per-user opt-in and timezone.
- **Concurrency & retries:** uid:yearWeek. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** week boundaries correct; hidden amount setting respected. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F35 — `publishWidgetSnapshot`
- **Trigger / caller:** event/task; authorized: Service account.
- **Input / schema:** `householdId,uid,layoutVersion,metricAsOf`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `snapshotVersion,ttlMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** emit minimised per-user widget cache, signal native refresh.
- **Concurrency & retries:** latest snapshot CAS by version. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** no raw receipt/member IDs, honor privacy, TTL expiry. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F36 — `saveWidgetLayout`
- **Trigger / caller:** callable; authorized: Authenticated active member.
- **Input / schema:** `householdId,items,expectedRevision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `newRevision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** persist per-uid household layout; triggers snapshot.
- **Concurrency & retries:** optimistic revision CAS. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** reject invalid widget type/order/size/max count, conflict resolution. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F37 — `verifyStorePurchase`
- **Trigger / caller:** callable; authorized: Authenticated user.
- **Input / schema:** `platform,storeProductId,transactionEvidence`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `entitlementState,validUntilMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** server verify Apple/Google, bind purchase to UID, update rights.
- **Concurrency & retries:** store transaction/purchaseToken unique; per-UID lock. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** pending/unverified/refund cannot activate, no price trust from client. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F38 — `handleAppStoreNotification`
- **Trigger / caller:** HTTPS webhook; authorized: Apple signed webhook.
- **Input / schema:** `signedPayload`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `ackStatus`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** validate JWS, query status when needed, update entitlement.
- **Concurrency & retries:** notificationUUID + transaction identity. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** reject bad signature/environment/bundle; handle renew/refund/grace. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F39 — `handleGooglePlayRtdn`
- **Trigger / caller:** PubSub event; authorized: Verified Google PubSub service.
- **Input / schema:** `messageId,purchaseToken,packageName,eventType`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `ackStatus`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** verify push/OIDC and fetch subscription via Play Developer API; update entitlement.
- **Concurrency & retries:** messageId & purchase token events. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** don't trust pubsub payload as purchased state; ack after durable capture. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F40 — `reconcileSubscriptionStatus`
- **Trigger / caller:** scheduled/task; authorized: Service account.
- **Input / schema:** `uid?/cursor`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `countUpdated,errors`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** check stale/expiring entitlement against store APIs, handle missed webhooks.
- **Concurrency & retries:** uid:provider:lastVerified window. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** expired/refunded revoked correctly; avoid flapping on transient outage. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F41 — `reconcileFinancialProjections`
- **Trigger / caller:** scheduled/task; authorized: Service account.
- **Input / schema:** `householdId?,partition?,dryRun?`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `mismatchCount,repairedCount`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** canonical recompute and replace projection/version, emit ops alert.
- **Concurrency & retries:** rebuild per partition/version. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** inject interrupted projector; detect incorrect total then repair. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F42 — `pruneExpiredInvitesAndDrafts`
- **Trigger / caller:** scheduled; authorized: Service account.
- **Input / schema:** `cutoffMs,dryRun?,cursor`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `deletedCount`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** remove expired invites, stale receipt drafts/images by retention.
- **Concurrency & retries:** cursor and idempotent lifecycle. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** preserve confirmed ledger and legally retained evidence. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F43 — `exportHouseholdData`
- **Trigger / caller:** callable/task; authorized: OWNER,ADMIN per scope.
- **Input / schema:** `householdId,format,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `jobId,status,downloadExpiry`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** authorize export, async create encrypted ZIP/CSV/JSON, private short TTL link.
- **Concurrency & retries:** one export per request; job state. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cross-household denied, zip traversal safe, complete financial history. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F44 — `deleteAccountData`
- **Trigger / caller:** callable/task; authorized: Authenticated owner of data.
- **Input / schema:** `scope=SELF_or_HOUSEHOLD,reauthProof,confirmation,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `jobId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** plan anonymization/ownership transfer, purge private tokens/images/export, append legal audit.
- **Concurrency & retries:** durable deletion workflow. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cannot erase other members ledger unilaterally, deadline/legal exceptions documented. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F45 — `auditCriticalAction`
- **Trigger / caller:** internal utility; authorized: Server handler only.
- **Input / schema:** `actorUid,action,resourceRef,correlationId,outcome`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `auditId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** append redacted audit record / external immutable log.
- **Concurrency & retries:** unique correlation/action/revision if replayed. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** no secrets/amounts/raw OCR, audit writing failure policy. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F46 — `updateUserProfile`
- **Trigger / caller:** callable; authorized: Authenticated user.
- **Input / schema:** `displayName,locale,defaultHouseholdId?,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `uid,revision`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** mirror validated profile; update own preferences without changing Auth ownership.
- **Concurrency & retries:** revision compare-and-set. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** cannot change other user; locale whitelist; default household membership. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F47 — `upsertBill`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,billId?,title,dueDate,amountMinor?,currency?,reminderOffsets,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `billId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create/update manually entered upcoming bill/reminder schedule.
- **Concurrency & retries:** requestId/revision. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** due date/timezone valid; no assumed recurring frequency; private title sanitized. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F48 — `recordBillSettlement`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,billId,postedLedgerEventId?,paymentStatus,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `billId,status`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** mark bill paid externally or associate existing expense event; do NOT auto-create duplicate expense.
- **Concurrency & retries:** billId+payment event/status transition dedupe. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** linked event same tenant; actual ledger expense counted once. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F49 — `upsertLiability`
- **Trigger / caller:** callable; authorized: OWNER,ADMIN,EDITOR.
- **Input / schema:** `householdId,liabilityId?,name,type,balanceMinor,currency,asOfMs,revision`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `liabilityId`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** record current debt liability balance with source/staleness, rebuild net worth.
- **Concurrency & retries:** requestId/revision. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** not counted twice with credit/loan account liability; total >=0. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F50 — `markNotificationRead`
- **Trigger / caller:** callable; authorized: Authenticated notification owner.
- **Input / schema:** `notificationId,readAtMs?`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `notificationId,readAtMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** write self-owned read timestamp for existing notification.
- **Concurrency & retries:** monotonic mark-as-read; repeated succeeds. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** reject foreign UID/unknown notification, no deep-link disclosure. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F51 — `initiateOwnershipTransfer`
- **Trigger / caller:** callable; authorized: Current household owner.
- **Input / schema:** `householdId,targetUid,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `transferRequestId,expiresAtMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** create short-lived pending ownership transfer invitation.
- **Concurrency & retries:** requestId with pending state. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** last owner safety; recipient active member; no automatic transfer without acceptance. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F52 — `acceptOwnershipTransfer`
- **Trigger / caller:** callable; authorized: Named target member.
- **Input / schema:** `transferRequestId,clientRequestId`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `householdId,newOwnerUid`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** consume transfer authorization, update household owner and member roles via recoverable operation.
- **Concurrency & retries:** token CAS + operation state + reconciliation. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** only target can accept; expired revoked request denied; owner single source of truth. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

### F53 — `getReceiptAccess`
- **Trigger / caller:** callable; authorized: job creator or authorized member.
- **Input / schema:** `householdId,jobId,purpose=REVIEW_or_EXPORT`; reject unknown fields, unsafe integers and invalid tenant-owned references. Use `CommandMeta` for user mutations.
- **Result:** `signedGetUrl,expiresAtMs`; use stable state values; return original response for exact idempotent retry.
- **Canonical side effects:** authorize receipt object read, mint short-lived scoped signed GET bearer URL.
- **Concurrency & retries:** ephemeral read; rate limit per uid/job. For scheduler/task use durable dedupe and bounded retry, not infinite recursive calls.
- **Required tests:** no receipt from other household, disallow expired/removed jobs. Also cover unauthorized cross-tenant, malformed payload, partial transient failure, repeated call and latency budget.
- **Observable signals:** log correlation ID, result state, latency, retry count and sanitized error code; emit counters for request/success/failure and domain-specific state changes; never log full sensitive input.

## Module organization

| Module | Functions | Dependency |
|---|---|---|
| `household` | F01-F07 | Auth, membership repo, invite token hash |
| `accounts` | F08-F10 | Account/category validation |
| `ledger` | F11-F15, F41 | Posting validator, canonical event repo, projector and reconciliation |
| `budgets` | F16-F17 | Summary projector, notification outbox |
| `wealth` | F18-F25 | Asset/valuation, holding/cashflow, period return calculator |
| `receipts` | F26-F29 | Storage, OCR adapter, parser, ledger command |
| `notifications` | F30-F34 | FCM, inbox, schedules, consent |
| `widgets` | F35-F36 | Layout registry, snapshot materializer |
| `billing` | F37-F40 | Apple/Google verifiers, entitlement state |
| `maintenance` | F42-F45 | data export, privacy erasure, audit |

| `user-bills` | F46-F50 | Profile, bills/liabilities, notification read acknowledgement |
| `ownership-receipts` | F51-F53 | ownership transfer, private receipt access |

## Security + migration acceptance
Every `callable` has auth-role test, every webhook has signed-provider negative test, every background handler has at-least-once replay test, every ledger projection has 1k-event deterministic reconciliation test. A successful Functions deploy without Rules, store webhook verification and monitoring configured does not mean production ready.
