/** Mây Family Finance — Callable Function Stub
 *
 * acceptHouseholdInvite: Accepts an invite token and joins a household.
 */

import { onCall } from 'firebase-functions/v2/https';

interface AcceptInviteInput {
  inviteToken: string;
}

export const acceptHouseholdInvite = onCall(
  { requireAuth: true, maxInstances: 5, timeoutSeconds: 30 },
  async (request) => ({ status: 'stubbed', message: 'Phase 1 implementation pending' }),
);
