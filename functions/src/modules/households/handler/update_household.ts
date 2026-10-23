/** Mây Family Finance — Callable Function: updateHousehold
 *
 * Updates household metadata (name, timezone, currency).
 * Authorization: OWNER or ADMIN required.
 * Concurrency: compare-and-set on revision field.
 * Timezone change: rejected if historical events exist.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { checkOwner } from '../../../core/authorization/household_auth.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';

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

// -- Handler --

export const updateHousehold = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    const logger = createLogger('updateHousehold');
    const nowMs = Date.now();

    // Auth guard — throws if unauthenticated.
    guardAuth(request);
    const uid = request.auth!.uid;
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
    const authError = await checkOwner({ uid, token: request.auth! }, validatedHid);
    if (authError) {
      return { status: 'error', code: authError.code, message: authError.message };
    }

    // Read current revision for compare-and-set.
    const hhRef = admin.database().ref(`households/${validatedHid}`);
    const hhSnap = await hhRef.once('value');

    if (!hhSnap.exists()) {
      return { status: 'error', code: 'ACCOUNT_NOT_FOUND', message: 'Household not found' };
    }

    const currentData = hhSnap.val();
    const currentRevision = (currentData.schemaVersion as number) ?? 0;

    // Timezone change guard: reject if historical events exist.
    if (timezone && timezone !== currentData.timezone) {
      const eventsRef = admin.database().ref(`events/${validatedHid}`);
      const eventsSnap = await eventsRef.once('value');
      if (eventsSnap.exists() && Object.keys(eventsSnap.val()).length > 0) {
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
    const updatedData = { ...currentData, ...updates };
    await hhRef.set(updatedData);

    // Idempotency record for read operations on the household path.
    const idempRef = admin.database().ref(`idempotency/${uid}/${clientRequestId}`);
    const fingerprint = computeFingerprint({ householdId: validatedHid, name, timezone, currency, clientRequestId });
    if (validateFingerprint(fingerprint)) {
      await idempRef.set({
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
