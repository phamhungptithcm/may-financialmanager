/** Mây Family Finance — Callable Function Stub: createHousehold
 *
 * Creates a new household for the first-time user.
 * Phase 1 implementation.
 */

import { onCall } from 'firebase-functions/v2/https';
import { guardAuth } from '../../../core/auth/auth_context.js';

// TODO Phase 1: Import validateFingerprint, computeIdempotencyKey
// import { validateFingerprint, computeIdempotencyKey } from '../../../core/idempotency/idempotency_service.js';
// TODO Phase 1: Import checkHouseholdAccess
// import { checkHouseholdAccess, actionRequires } from '../../../core/authorization/household_auth.js';

export const createHousehold = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  (request) => {
    guardAuth(request);
    // TODO Phase 1: Full implementation — validate name, generate hid,
    // write /households/{hid} and /members/{hid}/{uid} with role OWNER.
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
