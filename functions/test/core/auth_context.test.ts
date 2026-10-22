/** Mây Family Finance — Tests: AuthContext
 *
 * Verified invariants per BR-02 (specs/01):
 * - uid from context.auth.uid, not client body
 * - unauthenticated access rejected
 */

import { describe, it, expect } from 'vitest';
import { getAuthInfo, validateAppCheck } from '../../src/core/auth/auth_context.js';

// Mock https.CallableContext for testing.
function mockCallableContext(auth: { uid?: string; token?: unknown } | null) {
  return { auth };
}

describe('getAuthInfo', () => {
  it('returns AuthInfo when user is authenticated', () => {
    const ctx = mockCallableContext({
      uid: 'test_uid_123',
      token: { aud: 'test-app' },
    });
    const result = getAuthInfo(ctx);

    if (result instanceof Error) {
      throw new Error('Expected AuthInfo but got Error');
    }

    expect(result.uid).toBe('test_uid_123');
  });

  it('returns error when user is unauthenticated', () => {
    const ctx = mockCallableContext(null);
    const result = getAuthInfo(ctx);

    if (!(result instanceof Error)) {
      throw new Error('Expected Error but got AuthInfo');
    }

    expect(result.message).toBe('User must be authenticated');
  });
});

describe('validateAppCheck', () => {
  it('accepts non-null token when dev bypass is enabled', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'true';
    // Use a reasonably long token string (>10 chars).
    expect(validateAppCheck('very_long_token_value_12345')).toBe(true);
  });

  it('rejects null token when dev bypass is disabled', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'false';
    expect(validateAppCheck(null)).toBe(false);
  });

  it('accepts empty string in dev mode (falls through to falsy check, returns dev-bypass result)', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'true';
    // Empty string is falsy → hits early return → returns dev-bypass which is true.
    expect(validateAppCheck('')).toBe(true);
  });

  it('accepts token >= 11 chars when dev bypass is enabled', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'true';
    expect(validateAppCheck('1234567890a')).toBe(true); // exactly 11 chars
  });

  it('rejects token < 11 chars when dev bypass is enabled', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'true';
    expect(validateAppCheck('1234567890')).toBe(false); // exactly 10 chars, not > 10
    expect(validateAppCheck('short')).toBe(false); // 5 chars, not > 10
  });

  it('rejects empty string in production mode', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'false';
    // Empty string is falsy → hits early return (line 63) → isDevBypassAllowed() returns false.
    expect(validateAppCheck('')).toBe(false);
  });

  it('rejects invalid token in production mode', () => {
    process.env.APP_CHECK_DEV_BYPASS = 'false';
    // Short tokens without proper format should fail.
    expect(validateAppCheck(null)).toBe(false);
    expect(validateAppCheck('short')).toBe(false);
  });
});
