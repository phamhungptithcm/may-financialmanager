/** Mây Family Finance — Callable Function: acceptHouseholdInvite
 *
 * Accepts an invite token and joins a household.
 * Authorization: Authenticated user (no prior membership required).
 * Verifies invite existence, expiry, token hash match via atomic RTDB transaction.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';
import { isEmulator, getRTDBURL } from '../../../core/database/index.js';
import * as crypto from 'crypto';

// -- Zod schemas --

const AcceptInviteInputSchema = z.object({
  inviteId: z.string().min(1),
  householdId: z.string().min(1),
  inviteToken: z.string().min(16), // raw token must be at least 16 chars
  clientRequestId: z.string().uuid(),
});

type AcceptInviteInput = z.infer<typeof AcceptInviteInputSchema>;

// -- RTDB REST helpers (emulator mode) --

async function rtdbGet(...segments: string[]): Promise<unknown | null> {
  if (isEmulator()) {
    const baseUrl = getRTDBURL();
    const encoded = segments.map(encodeURIComponent).join('/');
    // NOTE: Do NOT use ?print=silent for reads — RTDB emulator returns HTTP 204
    // with empty body on GET+print=silent.
    const res = await fetch(`${baseUrl}${encoded}.json`);
    return res.status === 200 ? (await res.json()) : null;
  }
  const db = (global as any).__may_rtdb_instance;
  if (!db) throw new Error('RTDB not initialized in production');
  const snap = await db.ref(segments.join('/')).once('value');
  return snap.exists() ? snap.val() : null;
}

async function rtdbSet(segments: string[], data: unknown): Promise<void> {
  if (isEmulator()) {
    const baseUrl = getRTDBURL();
    const encoded = segments.map(encodeURIComponent).join('/');
    await fetch(`${baseUrl}${encoded}.json?print=silent`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return;
  }
  const db = (global as any).__may_rtdb_instance;
  if (!db) throw new Error('RTDB not initialized in production');
  await db.ref(segments.join('/')).set(data);
}

async function rtdbUpdate(baseSegments: string[], data: Record<string, unknown>): Promise<void> {
  if (isEmulator()) {
    const baseUrl = getRTDBURL();
    const basePath = baseSegments.map(encodeURIComponent).join('/');
    await fetch(`${baseUrl}${basePath}.json?print=silent`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return;
  }
  const db = (global as any).__may_rtdb_instance;
  if (!db) throw new Error('RTDB not initialized in production');
  await db.ref(baseSegments.join('/')).update(data);
}

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
    const existingMember = await rtdbGet('members', householdId, uid) as Record<string, unknown> | null;
    if (existingMember && typeof existingMember === 'object' && existingMember.status === 'ACTIVE') {
      logger.info('User already an active member, returning existing', {
        uid,
        householdId,
        correlationId: `corr_${nowMs}`,
      });
      return {
        householdId,
        role: (existingMember.role as string) ?? 'MEMBER',
      };
    }

    // Read invite record.
    const inviteData = await rtdbGet('invites', householdId, inviteId) as Record<string, unknown> | null;

    if (!inviteData || typeof inviteData !== 'object') {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite not found or expired',
      };
    }

    // Verify invite is for the correct household.
    if ((inviteData.householdId as string) !== householdId) {
      return {
        status: 'error',
        code: 'VALIDATION_ERROR',
        message: 'Invite does not match the specified household',
      };
    }

    // Verify invite has not expired.
    const expiresAtMs = inviteData.expiresAtMs as number;
    if (expiresAtMs && nowMs > expiresAtMs) {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite has expired',
      };
    }

    // Verify usage count hasn't exceeded max.
    const usageCount = (inviteData.usageCount as number) ?? 0;
    const maxUsage = (inviteData.maxUsage as number) ?? 1;
    if (usageCount >= maxUsage) {
      return {
        status: 'error',
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Invite has already been used',
      };
    }

    // Verify token hash match.
    const providedTokenHash = crypto.createHash('sha256').update(inviteToken).digest('hex');
    if (providedTokenHash !== (inviteData.tokenIdHash as string)) {
      return {
        status: 'error',
        code: 'VALIDATION_ERROR',
        message: 'Invalid invite token',
      };
    }

    const invitedRole = (inviteData.role as string) ?? 'MEMBER';

    // Atomic update to accept the invite.
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
    await rtdbUpdate([], updates);

    // Idempotency record.
    const fingerprint = computeFingerprint({ inviteId, householdId, uid });
    if (validateFingerprint(fingerprint)) {
      await rtdbSet(['idempotency', uid, clientRequestId], {
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
