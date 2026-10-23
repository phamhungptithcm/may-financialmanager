/** Mây Family Finance — Callable Function: createHousehold
 *
 * Creates a new household for the first-time user.
 * Idempotent via clientRequestId (SHA-256 fingerprint dedup).
 * Writes /households/{hid}, /members/{hid}/{uid}, /userHouseholds/{uid}/-{hid},
 * and default categories at /categories/{hid}.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
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

const CreateHouseholdInputSchema = z.object({
  name: z.string().min(1).max(50).trim(),
  timezone: z.enum(VALID_TIMEZONES),
  currency: z.enum(VALID_CURRENCIES),
  clientRequestId: z.string().uuid(),
});

type CreateHouseholdInput = z.infer<typeof CreateHouseholdInputSchema>;

// -- Default categories for every new household --

const DEFAULT_CATEGORIES: Array<{ name: string; kind: 'INCOME' | 'EXPENSE' }> = [
  { name: 'FOOD', kind: 'EXPENSE' },
  { name: 'TRANSPORT', kind: 'EXPENSE' },
  { name: 'SHOPPING', kind: 'EXPENSE' },
  { name: 'ENTERTAINMENT', kind: 'EXPENSE' },
  { name: 'HEALTHCARE', kind: 'EXPENSE' },
  { name: 'EDUCATION', kind: 'EXPENSE' },
  { name: 'UTILITIES', kind: 'EXPENSE' },
  { name: 'SALARY', kind: 'INCOME' },
  { name: 'OTHER_INCOME', kind: 'INCOME' },
];

// -- Handler --

export const createHousehold = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  async (request: CallableRequest) => {
    const logger = createLogger('createHousehold');
    const nowMs = Date.now();

    // Auth guard — throws if unauthenticated.
    guardAuth(request);
    const uid = request.auth!.uid;

    // Parse and validate input.
    let parsed: CreateHouseholdInput;
    try {
      parsed = CreateHouseholdInputSchema.parse(request.data);
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

    const { name, timezone, currency, clientRequestId } = parsed;

    // Idempotency: check if this uid + clientRequestId already produced a result.
    const idempRef = admin.database().ref(`idempotency/${uid}/${clientRequestId}`);
    let existingRecord = await idempRef.once('value');
    if (existingRecord.exists()) {
      const record = existingRecord.val();
      // Verify fingerprint matches current payload to prevent stale results.
      if (record.fingerprint && validateFingerprint(record.fingerprint)) {
        logger.info('Idempotent hit', { uid, clientRequestId });
        return {
          householdId: record.result.resourceId,
          status: 'accepted',
          createdAtMs: record.result.acceptedAtMs,
        };
      }
    }

    // Check if user already has a household — return existing instead of erroring.
    const userHouseholdsRef = admin.database().ref(`userHouseholds/${uid}`);
    const userHhSnapshot = await userHouseholdsRef.once('value');
    if (userHhSnapshot.exists()) {
      const children = userHhSnapshot.val();
      const existingHids = Object.keys(children).map((k) => children[k]);
      if (existingHids.length > 0) {
        const existingHid = existingHids[0];
        const hhRef = admin.database().ref(`households/${existingHid}`);
        const hhSnap = await hhRef.once('value');
        if (hhSnap.exists()) {
          logger.info('User already has a household, returning existing', { uid, householdId: existingHid });
          return {
            householdId: existingHid,
            status: 'accepted',
            createdAtMs: hhSnap.val().createdAtMs,
          };
        }
      }
    }

    // Compute fingerprint for this request.
    const fingerprint = computeFingerprint({ name, timezone, currency });
    if (!validateFingerprint(fingerprint)) {
      return { status: 'error', code: 'INVARIANT_FAILED', message: 'Idempotency fingerprint validation failed' };
    }

    // Generate household ID and create the household.
    const householdId = crypto.randomUUID();
    const ownerUid = uid;

    // Create default category IDs.
    const categories: Record<string, unknown> = {};
    for (const cat of DEFAULT_CATEGORIES) {
      const catId = `cat_${crypto.randomUUID().slice(0, 8)}`;
      categories[`_${cat.name}`] = {
        id: catId,
        name: cat.name,
        kind: cat.kind,
        createdAtMs: nowMs,
      };
    }

    // Atomic RTDB transaction to create household + member index.
    const categoriesRef = admin.database().ref(`categories/${householdId}`);

    await admin.database().ref().update({
      [`households/${householdId}`]: {
        id: householdId,
        ownerUid,
        name,
        currency,
        timezone,
        schemaVersion: 1,
        createdAtMs: nowMs,
      },
      [`members/${householdId}/${uid}`]: {
        role: 'OWNER',
        status: 'ACTIVE',
        joinedAtMs: nowMs,
      },
    });

    // Write user-to-household index (negative key = auto-sort by time).
    const negKey = `-${nowMs}`;
    await userHouseholdsRef.child(negKey).set(householdId);

    // Write default categories.
    await categoriesRef.set(categories);

    // Record idempotency result.
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

    logger.info('Household created successfully', {
      householdId,
      uid,
      nameLength: name.length,
      currency,
      correlationId: `corr_${nowMs}`,
    });

    return {
      householdId,
      status: 'accepted',
      createdAtMs: nowMs,
    };
  },
);
