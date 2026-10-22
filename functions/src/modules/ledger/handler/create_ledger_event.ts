/** Mây Family Finance — Callable Function Stub: createLedgerEvent
 *
 * Creates a new ledger transaction (income/expense/transfer).
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

export const createLedgerEvent = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
