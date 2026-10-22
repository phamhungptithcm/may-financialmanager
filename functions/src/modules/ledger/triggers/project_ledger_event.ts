/** Mây Family Finance — RTDB Trigger Stub: projectLedgerEvent
 *
 * RTDB trigger that projects ledger changes to analytics views.
 */

import { onValueWritten } from 'firebase-functions/v2/database';

// TODO Phase 1: Replace with actual ledger path after schema is finalized
const LEDGER_REF = '/ledger/{hid}/events/{eventId}';

export const projectLedgerEvent = onValueWritten(
  { ref: LEDGER_REF, timeoutSeconds: 60 },
  async (_change) => {
    // TODO Phase 1: Implement projection logic:
    // - Read the changed ledger event snapshot
    // - Project to /analytics/{householdId}/summaries by month/category
    return null;
  },
);
