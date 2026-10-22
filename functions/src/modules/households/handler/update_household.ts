/** Mây Family Finance — Callable Function Stub
 *
 * updateHousehold: Updates household settings (name, etc.).
 */

import { onCall } from 'firebase-functions/v2/https';

interface UpdateHouseholdInput {
  name?: string;
}

export const updateHousehold = onCall(
  {
    requireAuth: true,
    maxInstances: 5,
    timeoutSeconds: 30,
  },
  async (request) => ({ status: 'stubbed', message: 'Phase 1 implementation pending' }),
);
