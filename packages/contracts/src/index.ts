/** Mây Family Finance — Shared Domain Contracts (TypeScript)
 *
 * Source of truth for TypeScript types consumed by Cloud Functions modules.
 * Dart equivalents are generated or maintained in parallel in packages/contracts/dart/.
 *
 * Do NOT import Admin SDK here. Runtime validators (Zod) go in functions/src/core/validation/*.
 */

// -- Core identifiers --

export type UserId = string;
export type HouseholdId = string;
export type ISO4217 = 'VND' | 'USD';
export type EpochMs = number;

// -- Enums / types --

export type HouseholdRole = 'OWNER' | 'ADMIN' | 'EDITOR' | 'VIEWER';

export type AccountType = 'CASH' | 'BANK' | 'SAVINGS' | 'INVESTMENT' | 'CREDIT' | 'LOAN';

export type LedgerKind = 'EXPENSE' | 'INCOME' | 'TRANSFER' | 'REVERSAL';

export type AlertType = 'BUDGET' | 'BILL_DUE' | 'SAVINGS' | 'GROWTH' | 'WEEKLY';

export type SubscriptionState =
  | 'FREE'
  | 'PENDING'
  | 'ACTIVE'
  | 'GRACE'
  | 'BILLING_RETRY'
  | 'EXPIRED'
  | 'REVOKED';

export type MembershipStatus = 'ACTIVE' | 'REMOVED' | 'INVITED';

export type ReceiptJobState =
  | 'CREATED'
  | 'UPLOADED'
  | 'QUEUED'
  | 'PROCESSING'
  | 'REVIEW_REQUIRED'
  | 'CONFIRMED'
  | 'FAILED'
  | 'DISCARDED'
  | 'EXPIRED';

// -- Command envelope --

export interface CommandMeta {
  householdId: HouseholdId;
  clientRequestId: string;      // UUID v4, stable across retries
  schemaVersion: 1;
}

// -- Ledger commands --

export type CreateLedgerCommand = CommandMeta & ({
  kind: 'EXPENSE' | 'INCOME';
  accountId: string;
  categoryId: string;
  amountMinor: number;
  currency: ISO4217;
  occurredAtMs: EpochMs;
  merchant?: string;
  note?: string;
  receiptJobId?: string;
} & { kind: 'EXPENSE' | 'INCOME' } | {
  kind: 'TRANSFER';
  fromAccountId: string;
  toAccountId: string;
  amountMinor: number;
  currency: ISO4217;
  occurredAtMs: EpochMs;
  note?: string;
} & { kind: 'TRANSFER' });

// -- Domain entities --

export interface Posting {
  ledgerAccount: string;
  deltaMinor: number;
}

export interface LedgerEvent {
  eventId: string;
  clientRequestId: string;
  fingerprint: string;
  schemaVersion: 1;
  kind: LedgerKind;
  amountMinor: number;
  currency: ISO4217;
  occurredAtMs: EpochMs;
  createdAtMs: EpochMs;
  actorUid: UserId;
  postings: Record<string, Posting>;
  accountId?: string;
  categoryId?: string;
  reversesEventId?: string;
  correctsEventId?: string;
}

export interface AcceptedCommand {
  requestId: string;
  resourceId: string;
  status: 'ACCEPTED' | 'PROJECTED';
  acceptedAtMs: EpochMs;
  projectionVersion?: number;
}

export interface Household {
  id: HouseholdId;
  ownerUid: UserId;
  name: string;
  currency: ISO4217;
  timezone: string;
  schemaVersion: 1;
  createdAtMs: EpochMs;
}

export interface Account {
  id: string;
  householdId: HouseholdId;
  name: string;
  type: AccountType;
  currency: ISO4217;
  openingBalanceMinor: number;
  openingAtMs: EpochMs;
  archived: boolean;
}

export interface Budget {
  id: string;
  householdId: HouseholdId;
  categoryIds: string[];
  limitMinor: number;
  currency: ISO4217;
  period: 'WEEK' | 'MONTH';
  thresholdBps: number[];
  enabled: boolean;
}

// -- Receipt / OCR --

export interface OCRField<T> {
  value: T | null;
  confidence: number | null;  // calibrated from provider; null = unknown
  status: 'FOUND' | 'LOW_CONFIDENCE' | 'MISSING' | 'USER_CORRECTED';
}

export interface ReceiptDraft {
  jobId: string;
  householdId: HouseholdId;
  createdByUid: UserId;
  state: ReceiptJobState;
  provider: string;
  providerVersion: string;
  merchant: OCRField<string>;
  issueDate: OCRField<string>;
  totalMinor: OCRField<number>;
  currency: OCRField<ISO4217>;
  lineItems: Array<{
    name: string;
    quantityDecimal?: string;
    unitPriceMinor?: number;
    totalMinor?: number;
  }>;
  createdAtMs: EpochMs;
  reviewedAtMs?: EpochMs;
}

// -- Widgets --

export interface WidgetPlacement {
  instanceId: string;
  type: 'NET_WORTH' | 'INCOME' | 'EXPENSE' | 'BUDGET' | 'TOP_CATEGORIES' |
         'SAVINGS' | 'INVESTMENTS' | 'GOALS' | 'RECENT_TRANSACTIONS';
  size: 'SMALL' | 'WIDE';
  order: number;
  visible: boolean;
}

export interface WidgetLayout {
  revision: number;
  items: WidgetPlacement[];
  updatedAtMs: EpochMs;
}

// -- Notifications --

export interface NotificationItem {
  id: string;
  type: AlertType;
  title: string;
  bodySafe: string;       // Safe for push/inbox — never raw financial PII
  createdAtMs: EpochMs;
  deepLink: {
    route: string;
    householdId?: HouseholdId;
    resourceId?: string;
  };
  readAtMs?: EpochMs;
}

// -- Entitlements --

export interface Entitlement {
  uid: UserId;
  plan: 'FREE' | 'PLUS_MONTHLY' | 'PLUS_YEARLY';
  state: SubscriptionState;
  noAds: boolean;
  provider?: 'APPLE' | 'GOOGLE';
  storeProductId?: string;
  validUntilMs?: EpochMs;
  lastVerifiedAtMs?: EpochMs;
}

// -- API Error Response --

export interface ApiErrorDetail {
  code: 'AUTH_REQUIRED' | 'VALIDATION_ERROR' | 'HOUSEHOLD_ACCESS_DENIED' |
         'ROLE_DENIED' | 'ACCOUNT_NOT_FOUND' | 'CURRENCY_MISMATCH' |
         'DUPLICATE_CONFLICT' | 'ALREADY_REVERSED' | 'RECEIPT_NOT_READY' |
         'PURCHASE_UNVERIFIED' | 'RATE_LIMITED' | 'TEMPORARY_UNAVAILABLE' |
         'INVARIANT_FAILED';
  correlationId: string;
  retryable: boolean;
  fieldErrors?: Record<string, string>;
}

// -- Export --

export * from './schema/ledger-event';
export * from './schema/receipt-draft';
