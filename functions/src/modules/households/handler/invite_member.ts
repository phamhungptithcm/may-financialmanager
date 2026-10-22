/** Mây Family Finance — Callable Function Stub: inviteHouseholdMember
 *
 * Invites a Firebase user to join the household.
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

export const inviteHouseholdMember = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
