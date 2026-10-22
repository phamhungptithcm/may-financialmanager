/** Mây Family Finance — Callable Function Stub
 *
 * createLedgerEvent: Creates a new immutable ledger event.
 * Phase 2 implementation — validates postings, writes to /ledgerEvents/{hid}/{eventId}.
 */

import { onCall } from 'firebase-functions/v2/https';

interface CreateLedgerEventInput {
  householdId: string;
  clientRequestId: string;
  kind: 'EXPENSE' | 'INCOME' | 'TRANSFER';
  amountMinor: number;
  currency: string;
  accountId: string;
  categoryId?: string;
  title?: string;
  occurredAtMs: number;
}

export const createLedgerEvent = onCall(
  { requireAuth: true, maxInstances: 20, timeoutSeconds: 30 },
  async (request) => ({ status: 'stubbed', message: 'Phase 2 implementation pending' }),
);
