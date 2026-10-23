/** Mây Family Finance — Callable Function: updateHousehold
 *
 * Updates household metadata (name, timezone, currency).
 * Authorization: OWNER or ADMIN required.
 * Concurrency: compare-and-set on revision field.
 * Timezone change: rejected if historical events exist.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { checkOwner } from '../../../core/authorization/household_auth.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';
import { isEmulator, getRTDBURL } from '../../../core/database/index.js';
import { getDatabase } from '../../../core/database/db_client.js';

// -- Zod schemas --

const VALID_CURRENCIES = ['VND', 'USD'] as const;
const VALID_TIMEZONES = [
  'UTC',
  'Asia/Ho_Chi_Minh',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Anchorage',
  'Pacific/Honolulu',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Australia/Sydney',
  'Asia/Singapore',
  'Asia/Bangkok',
  'Asia/Jakarta',
  'Asia/Seoul',
] as const;

const UpdateHouseholdInputSchema = z.object({
  householdId: z.string().min(1),
  name: z.string().min(1).max(50).trim().optional(),
  timezone: z.enum(VALID_TIMEZONES).optional(),
  currency: z.enum(VALID_CURRENCIES).optional(),
  clientRequestId: z.string().uuid(),
}).refine(
  (data) => data.name !== undefined || data.timezone !== undefined || data.currency !== undefined,
  { message: 'At least one of name, timezone, or currency must be provided' },
);

type UpdateHouseholdInput = z.infer<typeof UpdateHouseholdInputSchema>;

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

// -- Handler --

export const updateHousehold = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    const logger = createLogger('updateHousehold');
    const nowMs = Date.now();

    // Auth guard — throws if unauthenticated.
    guardAuth(request);
    const auth = request.auth;
    if (!auth) {
      logger.error('Invariant: guardAuth passed but auth is null');
      throw new Error('Authentication unavailable');
    }
    const uid = auth.uid;
    const householdId = request.data?.householdId as string | undefined;

    if (!householdId) {
      return { status: 'error', code: 'VALIDATION_ERROR', message: 'householdId is required' };
    }

    // Parse and validate input.
    let parsed: UpdateHouseholdInput;
    try {
      const rawData = request.data ?? {};
      parsed = UpdateHouseholdInputSchema.parse({ ...rawData, householdId });
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

    const { householdId: validatedHid, name, timezone, currency, clientRequestId } = parsed;

    // RBAC: only OWNER can update household metadata.
    const authError = await checkOwner({ uid, token: auth }, validatedHid);
    if (authError) {
      return { status: 'error', code: authError.code, message: authError.message };
    }

    // Read current revision for compare-and-set.
    const hhData = await rtdbGet('households', validatedHid) as Record<string, unknown> | null;

    if (!hhData || typeof hhData !== 'object') {
      return { status: 'error', code: 'ACCOUNT_NOT_FOUND', message: 'Household not found' };
    }

    const currentRevision = (hhData.schemaVersion as number) ?? 0;

    // Timezone change guard: reject if historical events exist.
    if (timezone && timezone !== (hhData.timezone as string)) {
      const events = await rtdbGet('events', validatedHid) as Record<string, unknown> | null;
      if (events && typeof events === 'object' && Object.keys(events).length > 0) {
        logger.warn('Cannot change timezone — historical events exist', {
          householdId: validatedHid,
          correlationId: `corr_${nowMs}`,
        });
        return {
          status: 'error',
          code: 'VALIDATION_ERROR',
          message: 'Cannot change timezone while there are historical events. Contact support to migrate data.',
        };
      }
    }

    // Build update object with only provided fields.
    const updates: Record<string, unknown> = {};
    if (name !== undefined) updates.name = name;
    if (timezone !== undefined) updates.timezone = timezone;
    if (currency !== undefined) updates.currency = currency;
    updates.schemaVersion = currentRevision + 1;
    updates.updatedAtMs = nowMs;

    // Apply update with optimistic concurrency control.
    const updatedData = { ...hhData, ...updates };
    await rtdbSet(['households', validatedHid], updatedData);

    // Idempotency record for read operations on the household path.
    const fingerprint = computeFingerprint({ householdId: validatedHid, name, timezone, currency, clientRequestId });
    if (validateFingerprint(fingerprint)) {
      await rtdbSet(['idempotency', uid, clientRequestId], {
        fingerprint,
        result: {
          resourceId: validatedHid,
          status: 'ACCEPTED',
          acceptedAtMs: nowMs,
        },
        createdAtMs: nowMs,
        state: 'RESOLVED',
      });
    }

    logger.info('Household updated', {
      householdId: validatedHid,
      uid,
      changedFields: Object.keys(updates).filter((k) => k !== 'schemaVersion' && k !== 'updatedAtMs'),
      correlationId: `corr_${nowMs}`,
    });

    return {
      householdId: validatedHid,
      updatedAtMs: nowMs,
    };
  },
);
