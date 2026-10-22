/** Mây Family Finance — Callable Function Stub
 *
 * createHousehold: Creates a new household for the first-time user.
 * Phase 1 implementation — creates initial /households and /members records.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

/** Input schema for createHousehold callable function. */
interface CreateHouseholdInput {
  name: string;
}

/**
 * Creates a new household and assigns the caller as OWNER.
 * @name mayCreateHousehold
 */
export const createHousehold = onCall(
  {
    requireAuth: true,
    maxInstances: 10,
    timeoutSeconds: 30,
  },
  async (request) => {
    // TODO Phase 1: Implement full household creation flow.
    // Steps:
    // 1. Validate input (name length, characters)
    // 2. Check user has no existing household
    // 3. Generate unique household ID
    // 4. Write to /households/{hid} and /members/{hid}/{uid} with role OWNER
    // 5. Create default accounts/categories
    // 6. Return household ID

    const input = request.data as CreateHouseholdInput | undefined;
    if (!input?.name) {
      throw new HttpsError(
        'invalid-argument',
        'Household name is required',
      );
    }

    // Stub — placeholder until Phase 1 implementation.
    return { status: 'stubbed', message: 'Phase 1 implementation pending' };
  },
);
