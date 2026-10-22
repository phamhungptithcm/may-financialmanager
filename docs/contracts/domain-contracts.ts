/** Mây Family Finance reference domain contracts — adapt into a typed package.
 * Do not import Admin SDK here. Use runtime validators (Zod) at trusted endpoints.
 */
export type UserId = string;
export type HouseholdId = string;
export type ISO4217 = 'VND' | 'USD'; // v1 allowlist; expand with proper currency rules
export type EpochMs = number;
export type Money = Readonly<{ amountMinor: number; currency: ISO4217 }>;
export type HouseholdRole = 'OWNER' | 'ADMIN' | 'EDITOR' | 'VIEWER';
export type AccountType = 'CASH' | 'BANK' | 'SAVINGS' | 'INVESTMENT' | 'CREDIT' | 'LOAN';
export type LedgerKind = 'EXPENSE' | 'INCOME' | 'TRANSFER' | 'REVERSAL';
export type AlertType = 'BUDGET' | 'BILL_DUE' | 'SAVINGS' | 'GROWTH' | 'WEEKLY';
export type SubscriptionState = 'FREE' | 'PENDING' | 'ACTIVE' | 'GRACE' | 'BILLING_RETRY' | 'EXPIRED' | 'REVOKED';
export type MembershipStatus = 'ACTIVE' | 'REMOVED' | 'INVITED';

export interface CommandMeta {
  householdId: HouseholdId;
  clientRequestId: string;
  schemaVersion: 1;
}
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
} | {
  kind: 'TRANSFER';
  fromAccountId: string;
  toAccountId: string;
  amountMinor: number;
  currency: ISO4217;
  occurredAtMs: EpochMs;
  note?: string;
});
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
export type ReceiptJobState =
  | 'CREATED' | 'UPLOADED' | 'QUEUED' | 'PROCESSING'
  | 'REVIEW_REQUIRED' | 'CONFIRMED' | 'FAILED' | 'DISCARDED' | 'EXPIRED';
export interface OCRField<T> {
  value: T | null;
  confidence: number | null; // from provider or calibrated; undefined => unknown
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
  lineItems: Array<{ name: string; quantityDecimal?: string; unitPriceMinor?: number; totalMinor?: number }>;
  createdAtMs: EpochMs;
  reviewedAtMs?: EpochMs;
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
export type GrowthInsight =
  | { status: 'NO_DATA'; reason: string; period: string }
  | { status: 'AVAILABLE'; period: string; method: 'TWR' | 'XIRR'; returnBps: number; sourceAsOfMs: EpochMs; meetsGoal: boolean };
export interface WidgetPlacement {
  instanceId: string;
  type: 'NET_WORTH'|'INCOME'|'EXPENSE'|'BUDGET'|'TOP_CATEGORIES'|'SAVINGS'|'INVESTMENTS'|'GOALS'|'RECENT_TRANSACTIONS';
  size: 'SMALL'|'WIDE';
  order: number;
  visible: boolean;
}
export interface WidgetLayout {
  revision: number;
  items: WidgetPlacement[];
  updatedAtMs: EpochMs;
}
export interface NotificationItem {
  id: string;
  type: AlertType;
  title: string;
  bodySafe: string;
  createdAtMs: EpochMs;
  deepLink: { route: string; householdId?: HouseholdId; resourceId?: string };
  readAtMs?: EpochMs;
}
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
export interface ApiErrorDetail {
  code: 'AUTH_REQUIRED'|'VALIDATION_ERROR'|'HOUSEHOLD_ACCESS_DENIED'|'ROLE_DENIED'|
   'ACCOUNT_NOT_FOUND'|'CURRENCY_MISMATCH'|'DUPLICATE_CONFLICT'|'ALREADY_REVERSED'|
   'RECEIPT_NOT_READY'|'PURCHASE_UNVERIFIED'|'RATE_LIMITED'|'TEMPORARY_UNAVAILABLE'|'INVARIANT_FAILED';
  correlationId: string;
  retryable: boolean;
  fieldErrors?: Record<string,string>;
}
