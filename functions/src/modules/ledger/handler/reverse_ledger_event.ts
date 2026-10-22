/** Mây Family Finance — Callable Function Stub
 *
 * reverseLedgerEvent: Creates a reversal + replacement for an existing ledger event.
 */

import { onCall } from 'firebase-functions/v2/https';

interface ReverseInput {
  householdId: string;
  eventId: string;
  reason: string;
}

export const reverseLedgerEvent = onCall(
  { requireAuth: true, maxInstances: 10, timeoutSeconds: 30 },
  async (request) => ({ status: 'stubbed', message: 'Phase 2 implementation pending' }),
);
