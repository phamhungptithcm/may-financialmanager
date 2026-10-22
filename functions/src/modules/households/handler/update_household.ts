/** Mây Family Finance — Callable Function Stub: updateHousehold
 *
 * Updates household metadata (name, avatar, etc.).
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

export const updateHousehold = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
