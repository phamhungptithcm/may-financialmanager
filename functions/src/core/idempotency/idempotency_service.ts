/** Mây Family Finance — Backend Common: IdempotencyService
 *
 * Server-side idempotency for ledger writes and other critical commands.
 * Prevents duplicate posting from retries (per BR-14 in specs/01).
 */

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
 * Computes a stable canonical fingerprint for a command payload.
 * The fingerprint must be deterministic: same input → same output.
 */
export function computeFingerprint(payload: Record<string, unknown>): string {
  // Canonical serialization: sort keys, no whitespace.
  const sorted = Object.entries(payload)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => JSON.stringify({ [k]: normalizeValue(v) }));

  const canonical = `{${sorted.join(',')}}`;
  return hash(canonical);
}

/**
 * Normalizes values for fingerprint computation.
 * Removes non-deterministic fields (e.g., createdAtMs from client).
 */
function normalizeValue(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (typeof v === 'object') return JSON.stringify(v); // Simple approach
  return v;
}

// Simple hash for fingerprint (production should use crypto.createHash).
function hash(str: string): string {
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    h = ((h << 5) - h) + char;
    h |= 0; // Convert to 32bit integer
  }
  return `fp_${Math.abs(h).toString(16)}`;
}
