/** Mây Family Finance — Tests: IdempotencyService
 *
 * Verified invariants per BR-14 (specs/01):
 * - deterministic fingerprint computation
 * - SHA-256 hash output
 * - valid idempotency key format
 */

import { describe, it, expect } from 'vitest';
import {
  computeFingerprint,
  validateFingerprint,
  generateRequestId,
} from '../../src/core/idempotency/idempotency_service.js';

describe('computeFingerprint', () => {
  it('produces same output for identical payloads', () => {
    const payload = { householdId: 'hh_1', clientRequestId: 'cr_abc' };
    const f1 = computeFingerprint(payload);
    const f2 = computeFingerprint(payload);
    expect(f1).toBe(f2);
  });

  it('produces same output for different key order (deterministic)', () => {
    const payloadA = { a: 1, b: 2, c: 3 };
    const payloadB = { c: 3, b: 2, a: 1 };
    expect(computeFingerprint(payloadA)).toBe(computeFingerprint(payloadB));
  });

  it('produces SHA-256 hex output (64 chars)', () => {
    const fingerprint = computeFingerprint({ key: 'value' });
    expect(fingerprint.length).toBe(64);
    expect(/^([a-f0-9]{16}){4}$/.test(fingerprint)).toBe(true);
  });

  it('produces different output for different payloads', () => {
    const f1 = computeFingerprint({ amount: 100 });
    const f2 = computeFingerprint({ amount: 200 });
    expect(f1).not.toBe(f2);
  });

  it('handles null values deterministically', () => {
    const p1 = { key: null };
    const p2 = { key: null };
    expect(computeFingerprint(p1)).toBe(computeFingerprint(p2));
  });
});

describe('validateFingerprint', () => {
  it('accepts valid SHA-256 hex string (64 chars)', () => {
    // Use a real SHA-256 fingerprint (compute one, then validate it).
    const fp = computeFingerprint({ test: true });
    expect(validateFingerprint(fp)).toBe(true);
  });

  it('rejects empty string', () => {
    expect(validateFingerprint('')).toBe(false);
  });

  it('rejects non-string input', () => {
    expect(validateFingerprint(123 as unknown as string)).toBe(false);
  });

  it('rejects wrong-length string', () => {
    expect(validateFingerprint('abc')).toBe(false);
  });

  it('rejects invalid hex characters (uppercase)', () => {
    // SHA-256 outputs lowercase hex; uppercase should also be rejected by ^[a-f0-9]$
    const upperFp = computeFingerprint({ test: true }).toUpperCase();
    expect(validateFingerprint(upperFp)).toBe(false);
  });
});

describe('generateRequestId', () => {
  it('produces UUID v4 format (36 chars with hyphens)', () => {
    const id = generateRequestId();
    // Standard UUID v4: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (32 hex + 4 hyphens)
    expect(id.length).toBe(36);
    expect(/^[\da-f]{8}-[\da-f]{4}-4[\da-f]{3}-[89ab][\da-f]{3}-[\da-f]{12}$/i.test(id)).toBe(true);
  });

  it('produces lowercase hex output', () => {
    const id = generateRequestId();
    expect(id).toMatch(/^[\da-f-]+$/); // only lowercase hex and hyphens
  });

  it('produces unique IDs on repeated calls', () => {
    const ids = new Set<string>();
    for (let i = 0; i < 100; i++) {
      ids.add(generateRequestId());
    }
    expect(ids.size).toBe(100); // all unique in sample
  });

  it('version nibble is 4 (UUID v4)', () => {
    const id = generateRequestId();
    // Position 14 is the version nibble (after 8-4 positions)
    expect(id.charAt(14)).toBe('4');
  });

  it('variant nibble is 8/9/a/b (RFC 4122 variant)', () => {
    const id = generateRequestId();
    // Position 19 is the variant nibble
    expect(['8', '9', 'a', 'b'].includes(id.charAt(19))).toBe(true);
  });
});
