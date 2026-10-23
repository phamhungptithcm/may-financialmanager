/** Mây Family Finance — Callable Function: createHousehold
 *
 * Creates a new household for the first-time user.
 * Idempotent via clientRequestId (SHA-256 fingerprint dedup).
 * Writes /households/{hid}, /members/{hid}/{uid}, /userHouseholds/{uid}/-{hid},
 * and default categories at /categories/{hid}.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { guardAuth } from '../../../core/auth/auth_context.js';
import { computeFingerprint, validateFingerprint } from '../../../core/idempotency/idempotency_service.js';
import { createLogger } from '../../../core/logging/structured_logger.js';
import { isEmulator, getRTDBURL } from '../../../core/database/index.js';

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

// -- RTDB REST helpers (emulator mode) --

/** Build a safe RTDB REST path from segments. */
function rtdbPath(...segments: string[]): string {
  const baseUrl = getRTDBURL();
  // Encode each segment to handle @, ., #, etc.
  const encoded = segments.map(encodeURIComponent).join('/');
  return `${baseUrl}${encoded}.json?print=silent`;
}

async function rtdbGet(...segments: string[]): Promise<unknown | null> {
  if (isEmulator()) {
    const baseUrl = getRTDBURL();
    // NOTE: Do NOT use ?print=silent for reads in emulator mode.
    // The RTDB emulator returns HTTP 204 with empty body for GET+print=silent,
    // which would be misinterpreted as "not found". Only production servers
    // correctly honor the spec (return data + 200). For writes we use print=silent
    // to suppress echo on successful operations.
    const encoded = segments.map(encodeURIComponent).join('/');
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
    const url = `${rtdbPath(...segments)}`;
    await fetch(url, {
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
    const existingRecord = await rtdbGet('idempotency', uid, clientRequestId);
    if (existingRecord && typeof existingRecord === 'object' && 'fingerprint' in existingRecord) {
      const record = existingRecord as Record<string, unknown>;
      if (record.fingerprint && validateFingerprint(record.fingerprint as string)) {
        logger.info('Idempotent hit', { uid, clientRequestId });
        return {
          householdId: (record.result as Record<string, unknown>)?.resourceId as string,
          status: 'accepted',
          createdAtMs: (record.result as Record<string, unknown>)?.acceptedAtMs as number,
        };
      }
    }

    // Check if user already has a household — return existing instead of erroring.
    const userHouseholds = await rtdbGet('userHouseholds', uid) as Record<string, unknown> | null;
    if (userHouseholds && typeof userHouseholds === 'object') {
      const hids = Object.values(userHouseholds);
      for (const hid of hids) {
        if (typeof hid !== 'string') continue;
        const hhSnap = await rtdbGet('households', hid) as Record<string, unknown> | null;
        if (hhSnap && typeof hhSnap === 'object' && 'createdAtMs' in hhSnap) {
          logger.info('User already has a household, returning existing', { uid, householdId: hid });
          return {
            householdId: hid,
            status: 'accepted',
            createdAtMs: (hhSnap as Record<string, unknown>).createdAtMs as number,
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

    // Write household + member via RTDB update.
    await rtdbUpdate([''], {
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
        role: 'OWNER' as const,
        status: 'ACTIVE' as const,
        joinedAtMs: nowMs,
      },
    });

    // Write user-to-household index (negative key = auto-sort by time).
    const negKey = `-${nowMs}`;
    await rtdbSet(['userHouseholds', uid, negKey], householdId);

    // Write default categories.
    await rtdbSet(['categories', householdId], categories);

    // Record idempotency result.
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
