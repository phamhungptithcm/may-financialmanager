/** Mây Family Finance — Callable Function Stub: confirmReceiptDraft
 *
 * Confirms a receipt draft and creates the corresponding ledger event.
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

export const confirmReceiptDraft = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
