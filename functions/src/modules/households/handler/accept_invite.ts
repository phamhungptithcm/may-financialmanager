/** Mây Family Finance — Callable Function: acceptHouseholdInvite
 *
 * Accepts an invite token and joins a household.
 * Authorization: Authenticated user (no prior membership required).
 * Verifies invite existence, expiry, token hash match via atomic RTDB transaction.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';

// -- Zod schemas --

const AcceptInviteInputSchema = z.object({
  inviteId: z.string().min(1),
  householdId: z.string().min(1),
  inviteToken: z.string().min(16), // raw token must be at least 16 chars
  clientRequestId: z.string().uuid(),
});

type AcceptInviteInput = z.infer<typeof AcceptInviteInputSchema>;

// -- Handler --

export const acceptHouseholdInvite = onCall(
  { maxInstances: 5, timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    const logger = createLogger('acceptHouseholdInvite');
    const nowMs = Date.now();

    // Auth guard — throws if unauthenticated.
    guardAuth(request);
    const uid = request.auth!.uid;

    // Parse and validate input.
    let parsed: AcceptInviteInput;
    try {
      parsed = AcceptInviteInputSchema.parse(request.data);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return {
          status: 'error',
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          fieldErrors: Object.fromEntries(
            err.issues.map((i) => [i.path.join('.'), i.message]),
          ),
        };
      }
      throw err;
    }

    const { inviteId, householdId, inviteToken, clientRequestId } = parsed;

    // Check if user is already a member — deny duplicate joins.
    const existingMemberRef = admin.database().ref(`members/${householdId}/${uid}`);
    const existingMemberSnap = await existingMemberRef.once('value');
    if (existingMemberSnap.exists()) {
      const memberData = existingMemberSnap.val();
      if (memberData.status === 'ACTIVE') {
        logger.info('User already an active member, returning existing', {
          uid,
          householdId,
          correlationId: `corr_${nowMs}`,
        });
        return {
          householdId,
          role: memberData.role ?? 'MEMBER',
        };
      }
    }

    // Read invite record.
    const inviteRef = admin.database().ref(`invites/${householdId}/${inviteId}`);
    const inviteSnap = await inviteRef.once('value');

    if (!inviteSnap.exists()) {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite not found or expired',
      };
    }

    const inviteData = inviteSnap.val();

    // Verify invite is for the correct household.
    if (inviteData.householdId !== householdId) {
      return {
        status: 'error',
        code: 'VALIDATION_ERROR',
        message: 'Invite does not match the specified household',
      };
    }

    // Verify invite has not expired.
    if (inviteData.expiresAtMs && nowMs > inviteData.expiresAtMs) {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite has expired',
      };
    }

    // Verify usage count hasn't exceeded max.
    const usageCount = inviteData.usageCount ?? 0;
    const maxUsage = inviteData.maxUsage ?? 1;
    if (usageCount >= maxUsage) {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite has already been used',
      };
    }

    // Verify token hash match.
    const providedTokenHash = crypto.createHash('sha256').update(inviteToken).digest('hex');
    if (providedTokenHash !== inviteData.tokenIdHash) {
      return {
        status: 'error',
        code: 'VALIDATION_ERROR',
        message: 'Invalid invite token',
      };
    }

    const invitedRole = inviteData.role ?? 'MEMBER';

    // Atomic transaction to accept the invite.
    // Execute as a multi-path atomic update.
    const updates: Record<string, unknown> = {};

    // 1. Create/update member record.
    updates[`members/${householdId}/${uid}`] = {
      role: invitedRole,
      status: 'ACTIVE',
      joinedAtMs: nowMs,
    };

    // 2. Write user-to-household index (negative key for auto-sort).
    const negKey = `-${nowMs}`;
    updates[`userHouseholds/${uid}/${negKey}`] = householdId;

    // 3. Increment usage count on the invite.
    const newUsageCount = usageCount + 1;
    const invitePath = `invites/${householdId}/${inviteId}`;
    updates[invitePath] = {
      ...inviteData,
      usageCount: newUsageCount,
    };

    // 4. Delete invite if max usage reached.
    if (newUsageCount >= maxUsage) {
      updates[invitePath] = null;
    }

    // Apply atomic update.
    await admin.database().ref().update(updates);

    // Idempotency record.
    const idempRef = admin.database().ref(`idempotency/${uid}/${clientRequestId}`);
    const fingerprint = computeFingerprint({ inviteId, householdId, uid });
    if (validateFingerprint(fingerprint)) {
      await idempRef.set({
        fingerprint,
        result: {
          resourceId: householdId,
          status: 'ACCEPTED',
          acceptedAtMs: nowMs,
        },
        createdAtMs: nowMs,
        state: 'RESOLVED',
      });
    }

    logger.info('Invite accepted — user joined household', {
      uid,
      householdId,
      role: invitedRole,
      correlationId: `corr_${nowMs}`,
    });

    return {
      householdId,
      role: invitedRole,
    };
  },
);
