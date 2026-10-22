/** Mây Family Finance — RTDB Trigger Stub
 *
 * projectLedgerEvent: Reads new ledger events and writes read models.
 * Phase 2 implementation — projections for transactionList, accountMovements, summaries.
 */

import { onValueWritten } from 'firebase-functions/v2/database';

/**
 * Triggers when a new event is written to /ledgerEvents/{hid}/{eventId}.
 * Projects the event into denormalized read models.
 */
export const projectLedgerEvent = onValueWritten(
  { secret: 'FIREBASE_DB_URL', timeoutSeconds: 120 },
  async (event) => {
    // TODO Phase 2: Implement projection logic.
    // Steps:
    // 1. Read the ledger event from event.data
    // 2. Compute period key from occurredAtMs + household timezone
    // 3. Write to /transactionList/{hid}/{YYYYMM}/{eventId}
    // 4. Write to /accountMovements/{hid}/{accountId}/{YYYYMM}/{eventId}
    // 5. Update /summaries/{hid}/{YYYYMM}
    // 6. Write checkpoint for reconciliation
    return { status: 'stubbed', message: 'Phase 2 implementation pending' };
  },
);
