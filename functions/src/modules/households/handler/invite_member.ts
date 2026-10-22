/** Mây Family Finance — Callable Function Stub
 *
 * inviteHouseholdMember: Creates an invite and sends notification.
 */

import { onCall } from 'firebase-functions/v2/https';

interface InviteInput {
  householdId: string;
  email: string;
  role: string;
}

export const inviteHouseholdMember = onCall(
  { requireAuth: true, maxInstances: 5, timeoutSeconds: 30 },
  async (request) => ({ status: 'stubbed', message: 'Phase 1 implementation pending' }),
);
