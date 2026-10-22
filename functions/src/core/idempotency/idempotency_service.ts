/** Mây Family Finance — Backend Common: IdempotencyService
 *
 * Server-side idempotency for ledger writes and other critical commands.
 * Prevents duplicate posting from retries (per BR-14 in specs/01).
 */

import * as crypto from 'crypto';

/** State transitions for operation deduplication. */
export enum IdempotencyState {
  RESOLVED = 'RESOLVED',     // Result returned successfully
  PENDING = 'PENDING',        // Operation in progress
  CONFLICTING = 'CONFLICTING', // Same key, different payload
}

/** Schema for idempotency key storage in /idempotency/{hid}/{uid}/{requestId}. */
export interface IdempotencyRecord {
  fingerprint: string;    // SHA-256 of canonical payload
  result: {
    resourceId: string;
    status: 'ACCEPTED' | 'PROJECTED';
    acceptedAtMs: number;
  };
  createdAtMs: number;
  state: IdempotencyState;
}

/**
 * Service interface for idempotency operations.
 * Concrete implementation uses RTDB /idempotency/{hid}/{uid}/{requestId}.
 */
export interface IdempotencyRepository {
  /** Check if a key has been resolved, and optionally verify fingerprint match. */
  get(key: string): Promise<IdempotencyRecord | null>;

  /** Create a pending record (if no existing record exists). */
  createPending(key: string, fingerprint: string): Promise<boolean>;

  /** Mark a key as resolved with the result. */
  markResolved(
    key: string,
    fingerprint: string,
    result: IdempotencyRecord['result'],
  ): Promise<'CREATED' | 'EXISTING'>;

  /** Delete expired records (for cleanup tasks). */
  deleteExpired(beforeMs: number): Promise<number>;
}

/**
 * Computes a stable SHA-256 canonical fingerprint for a command payload.
 * The fingerprint must be deterministic: same input → same output.
 */
export function computeFingerprint(payload: Record<string, unknown>): string {
  // Canonical serialization: sort keys for deterministic order.
  const sorted = Object.entries(payload)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => JSON.stringify({ [k]: normalizeValue(v) }));

  const canonical = `{${sorted.join(',')}}`;
  return crypto.createHash('sha256').update(canonical).digest('hex');
}

/**
 * Normalizes values for fingerprint computation.
 * Removes non-deterministic fields (e.g., createdAtMs from client).
 */
function normalizeValue(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (typeof v === 'boolean') return v ? true : false;
  if (typeof v === 'number') {
    // Ensure consistent number representation for safe integers.
    if (Number.isSafeInteger(v)) return v;
    // For floats, preserve exact string representation.
    return String(v);
  }
  if (typeof v === 'string') return v;
  if (typeof v === 'object') {
    if (Array.isArray(v)) {
      return v.map(normalizeValue);
    }
    // Objects: recursive canonicalization via sorted key pairs.
    const entries = Object.entries(v)
      .sort(([a], [b]) => a.localeCompare(b));
    return Object.fromEntries(entries);
  }
  return v;
}

/**
 * Computes an idempotency key from household, user ID, and client request ID.
 * Key format: <householdId>/<userId>/<requestId> (used as RTDB path segment).
 */
export function computeIdempotencyKey(
  householdId: string,
  userId: string,
  requestId: string,
): string {
  return `${householdId}/${userId}/${requestId}`;
}

/**
 * Generates a cryptographically secure UUID v4 request ID.
 */
export function generateRequestId(): string {
  return crypto.randomUUID();
}

/**
 * Validates that a fingerprint is a valid SHA-256 hex string (64 lowercase hex chars).
 */
export function validateFingerprint(fingerprint: unknown): boolean {
  if (typeof fingerprint !== 'string') return false;
  if (fingerprint.length !== 64) return false;
  return /^[a-f0-9]{64}$/.test(fingerprint);
}
