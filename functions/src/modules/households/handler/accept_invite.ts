/** Mây Family Finance — Callable Function Stub: acceptHouseholdInvite
 *
 * Accepts an invite token and joins a household.
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

export const acceptHouseholdInvite = onCall(
  { maxInstances: 5, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
