/** Mây Family Finance — Callable Function Stub
 *
 * confirmReceiptDraft: User confirms OCR-extracted receipt fields.
 */

import { onCall } from 'firebase-functions/v2/https';

interface ConfirmReceiptInput {
  householdId: string;
  jobId: string;
  totalMinor: number;
  currency: string;
  items: unknown[];
}

export const confirmReceiptDraft = onCall(
  { requireAuth: true, maxInstances: 10, timeoutSeconds: 60 },
  async (request) => ({ status: 'stubbed', message: 'Phase 4 implementation pending' }),
);
