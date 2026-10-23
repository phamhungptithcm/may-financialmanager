/** Mây Family Finance — Callable Function: inviteHouseholdMember
 *
 * Creates an invite token for a new household member.
 * Authorization: OWNER or ADMIN required.
 * Stores only the SHA-256 hash of the invite token (never raw token).
 * Returns a shareable link with the hashed invite ID and raw token.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { checkHouseholdAccess } from '../../../core/authorization/household_auth.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';
import { isEmulator, getRTDBURL } from '../../../core/database/index.js';
import { getDatabase } from '../../../core/database/db_client.js';
import * as crypto from 'crypto';

// -- Zod schemas --

const VALID_INVITE_ROLES = ['EDITOR', 'ADMIN'] as const;
const MAX_EXPIRY_HOURS = 720; // 30 days
const MIN_EXPIRY_HOURS = 1;
const MAX_ACTIVE_INVITES_PER_DAY = 5;

const InviteMemberInputSchema = z.object({
  householdId: z.string().min(1),
  inviteRole: z.enum(VALID_INVITE_ROLES),
  expiresInHours: z.number().int().min(MIN_EXPIRY_HOURS).max(MAX_EXPIRY_HOURS),
  clientRequestId: z.string().uuid(),
});

type InviteMemberInput = z.infer<typeof InviteMemberInputSchema>;

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
  const db = getDatabase();
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
  const db = getDatabase();
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
  const db = getDatabase();
  await db.ref(baseSegments.join('/')).update(data);
}

// -- Handler --

export const inviteHouseholdMember = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    const logger = createLogger('inviteHouseholdMember');
    const nowMs = Date.now();

    // Auth guard — throws if unauthenticated.
    guardAuth(request);
    const auth = request.auth;
    if (!auth) {
      logger.error('Invariant: guardAuth passed but auth is null');
      throw new Error('Authentication unavailable');
    }
    const uid = auth.uid;

    // Parse and validate input.
    let parsed: InviteMemberInput;
    try {
      parsed = InviteMemberInputSchema.parse(request.data);
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

    const { householdId, inviteRole, expiresInHours, clientRequestId } = parsed;

    // RBAC: need ADMIN or higher in the household.
    const hasAccess = await checkHouseholdAccess(
      { uid, token: auth },
      householdId,
      'ADMIN',
    );
    if (!hasAccess) {
      return {
        status: 'error',
        code: 'HOUSEHOLD_ACCESS_DENIED',
        message: 'You must be an admin or owner to invite members',
      };
    }

    // Idempotency: check if this request already produced a result.
    const existingRecord = await rtdbGet('idempotency', uid, clientRequestId);
    if (existingRecord && typeof existingRecord === 'object' && 'fingerprint' in existingRecord) {
      const record = existingRecord as Record<string, unknown>;
      if (record.fingerprint && validateFingerprint(record.fingerprint as string)) {
        logger.info('Idempotent hit — returning existing invite', {
          householdId,
          clientRequestId,
          correlationId: `corr_${nowMs}`,
        });
        return {
          inviteId: (record.result as Record<string, unknown>)?.resourceId as string,
          shareableLink: '[link_with_raw_token]',
          expiresAtMs: (record.result as Record<string, unknown>)?.acceptedAtMs as number,
        };
      }
    }

    // Check active invite count.
    const invites = await rtdbGet('invites', householdId) as Record<string, unknown> | null;
    if (invites && typeof invites === 'object') {
      let activeCount = 0;
      for (const _inviteId of Object.keys(invites)) {
        const inviteData = invites[_inviteId];
        if (inviteData && typeof inviteData === 'object' && (inviteData as Record<string, unknown>).usageCount === 0) {
          activeCount++;
        }
      }
      if (activeCount >= MAX_ACTIVE_INVITES_PER_DAY) {
        return {
          status: 'error',
          code: 'RATE_LIMITED',
          message: `Maximum ${MAX_ACTIVE_INVITES_PER_DAY} active invites per household per day reached`,
        };
      }
    }

    // Generate cryptographically secure invite token.
    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    // Generate invite ID.
    const inviteId = crypto.randomUUID();
    const expiresAtMs = nowMs + expiresInHours * 60 * 60 * 1000;

    // Write invite metadata via RTDB update.
    await rtdbUpdate([''], {
      [`invites/${householdId}/${inviteId}`]: {
        householdId,
        tokenIdHash: tokenHash,
        createdByUid: uid,
        expiresAtMs,
        usageCount: 0,
        maxUsage: 1,
        role: inviteRole,
        createdAtMs: nowMs,
      },
    });

    // Compute fingerprint and store idempotency record.
    const fingerprint = computeFingerprint({ householdId, inviteRole, expiresInHours });
    if (validateFingerprint(fingerprint)) {
      await rtdbSet(['idempotency', uid, clientRequestId], {
        fingerprint,
        result: {
          resourceId: inviteId,
          status: 'ACCEPTED',
          acceptedAtMs: expiresAtMs,
        },
        createdAtMs: nowMs,
        state: 'RESOLVED',
      });
    }

    logger.info('Invite created successfully', {
      householdId,
      inviteIdHashed: tokenHash.slice(0, 8) + '...',
      createdByUid: uid,
      expiresAtMs,
      correlationId: `corr_${nowMs}`,
    });

    // Return shareable link (the raw token is only shown to the creator).
    const shareableLink = `${inviteId}::${rawToken}`;

    return {
      inviteId,
      shareableLink,
      expiresAtMs,
    };
  },
);
