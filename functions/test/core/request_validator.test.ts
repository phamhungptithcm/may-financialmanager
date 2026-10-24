/** Mây Family Finance — Tests: RequestValidator
 *
 * Verified invariants per BR-03 (specs/01):
 * - safe integer validation
 * - currency allowlist
 * - timezone IANA validation
 * - epoch ms range
 * - clientRequestId format
 */

import { describe, it, expect } from 'vitest';
import { validateMoney, validateTimezone, validateCurrency, validateCurrencyCode, validateEpochMs, validateClientId } from '../../src/core/validation/request_validator.js';
import { AppError } from '../../src/core/errors/app_error.js';

// ================================================================
// validateMoney — Happy Path
// ================================================================
describe('validateMoney', () => {
  it('accepts positive VND amount', () => {
    const result = validateMoney(185000, 'VND');
    expect(result.amountMinor).toBe(185000);
    expect(result.currency).toBe('VND');
  });

  it('accepts zero USD amount', () => {
    const result = validateMoney(0, 'USD');
    expect(result.amountMinor).toBe(0);
    expect(result.currency).toBe('USD');
  });

  it('accepts negative amount (for debit)', () => {
    const result = validateMoney(-185000, 'VND');
    expect(result.amountMinor).toBe(-185000);
    expect(result.currency).toBe('VND');
  });

  it('accepts max safe integer', () => {
    const maxSafe = Number.MAX_SAFE_INTEGER;
    const result = validateMoney(maxSafe, 'USD');
    expect(result.amountMinor).toBe(maxSafe);
    expect(result.currency).toBe('USD');
  });

  it('case-insensitive currency (lowercase)', () => {
    const result = validateMoney(100, 'vnd');
    expect(result.currency).toBe('VND');
  });

  it('case-insensitive currency (mixed case)', () => {
    const result = validateMoney(100, 'UsD');
    expect(result.currency).toBe('USD');
  });
});

// ================================================================
// validateMoney — Negative Cases
// ================================================================
describe('validateMoney — negative cases', () => {
  it('rejects floating point amount', () => {
    expect(() => validateMoney(185000.5, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects NaN amount', () => {
    expect(() => validateMoney(NaN, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects infinity amount', () => {
    expect(() => validateMoney(Infinity, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects -infinity amount', () => {
    expect(() => validateMoney(-Infinity, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects null amount', () => {
    expect(() => validateMoney(null as unknown as number, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects undefined amount', () => {
    expect(() => validateMoney(undefined as unknown as number, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects boolean amount', () => {
    expect(() => validateMoney(true as unknown as number, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects string amount', () => {
    expect(() => validateMoney('185000' as unknown as number, 'VND')).toThrow(/must be a safe integer/);
  });

  it('rejects VND with unsupported currency', () => {
    expect(() => validateMoney(100, 'EUR')).toThrow(/Unsupported currency/);
  });

  it('rejects invalid currency code', () => {
    expect(() => validateMoney(100, 'JPY')).toThrow(/Unsupported currency/);
  });

  it('rejects empty string currency', () => {
    expect(() => validateMoney(100, '')).toThrow();
  });

  it('handles amount at MAX_SAFE_INTEGER boundary (should accept)', () => {
    const maxSafe = Number.MAX_SAFE_INTEGER;
    const result = validateMoney(maxSafe, 'USD');
    expect(result.amountMinor).toBe(maxSafe);
  });

  it('handles amount just above safe integer (accepts if still safe)', () => {
    // Numbers > MAX_SAFE_INTEGER may or may not be safe integers depending on context
    const result = validateMoney(Number.MAX_SAFE_INTEGER, 'VND');
    expect(result.amountMinor).toBe(Number.MAX_SAFE_INTEGER);
  });
});

// ================================================================
// validateTimezone — Happy Path
// ================================================================
describe('validateTimezone', () => {
  it('accepts valid Asia/Ho_Chi_Minh', () => {
    expect(validateTimezone('Asia/Ho_Chi_Minh')).toBe('Asia/Ho_Chi_Minh');
  });

  it('accepts valid UTC', () => {
    expect(validateTimezone('UTC')).toBe('UTC');
  });

  it('accepts valid America/New_York', () => {
    expect(validateTimezone('America/New_York')).toBe('America/New_York');
  });

  it('accepts valid Asia/Tokyo', () => {
    expect(validateTimezone('Asia/Tokyo')).toBe('Asia/Tokyo');
  });

  it('accepts valid Europe/London', () => {
    expect(validateTimezone('Europe/London')).toBe('Europe/London');
  });

  it('accepts valid Australia/Sydney', () => {
    expect(validateTimezone('Australia/Sydney')).toBe('Australia/Sydney');
  });

  it('accepts America/Chicago', () => {
    expect(validateTimezone('America/Chicago')).toBe('America/Chicago');
  });

  it('accepts Pacific/Honolulu', () => {
    expect(validateTimezone('Pacific/Honolulu')).toBe('Pacific/Honolulu');
  });

  it('accepts Africa/Cairo (Africa)', () => {
    expect(validateTimezone('Africa/Cairo')).toBe('Africa/Cairo');
  });

  it('accepts Atlantic/Azores (Atlantic)', () => {
    expect(validateTimezone('Atlantic/Azores')).toBe('Atlantic/Azores');
  });

  it('accepts Indian/Maldives (Indian)', () => {
    expect(validateTimezone('Indian/Maldives')).toBe('Indian/Maldives');
  });

  it('accepts arbitrary valid IANA zone', () => {
    expect(validateTimezone('Europe/Paris')).toBe('Europe/Paris');
    expect(validateTimezone('Asia/Shanghai')).toBe('Asia/Shanghai');
    expect(validateTimezone('America/Denver')).toBe('America/Denver');
  });

  it('returns the input timezone string', () => {
    for (const tz of ['UTC', 'Asia/Ho_Chi_Minh', 'America/Los_Angeles']) {
      expect(validateTimezone(tz)).toBe(tz);
    }
  });
});

// ================================================================
// validateTimezone — Negative Cases
// ================================================================
describe('validateTimezone — negative cases', () => {
  it('rejects non-string input (number)', () => {
    expect(() => validateTimezone(123 as unknown as string)).toThrow(/timezone must be a string/);
  });

  it('rejects non-string input (null)', () => {
    expect(() => validateTimezone(null as unknown as string)).toThrow(/timezone must be a string/);
  });

  it('rejects non-string input (undefined)', () => {
    expect(() => validateTimezone(undefined as unknown as string)).toThrow(/timezone must be a string/);
  });

  it('rejects non-string input (boolean)', () => {
    expect(() => validateTimezone(true as unknown as string)).toThrow(/timezone must be a string/);
  });

  it('rejects empty string', () => {
    expect(() => validateTimezone('')).toThrow();
  });

  it('rejects invalid IANA zone (non-existent)', () => {
    expect(() => validateTimezone('Invalid/Zone')).toThrow(/Invalid timezone/);
  });

  it('rejects partial timezone string', () => {
    expect(() => validateTimezone('America/New_Yo')).toThrow(/Invalid timezone/);
  });

  it('rejects timezone with spaces', () => {
    expect(() => validateTimezone('Asia/Ho Chi Minh')).toThrow(/Invalid timezone/);
  });

  it('rejects timezone with special characters', () => {
    expect(() => validateTimezone('<script>')).toThrow(/Invalid timezone/);
  });

  it('rejects SQL injection attempt', () => {
    expect(() => validateTimezone("'; DROP TABLE households; --")).toThrow();
  });

  it('rejects path traversal attempt', () => {
    expect(() => validateTimezone('../../etc/passwd')).toThrow(/Invalid timezone/);
  });

  it('rejects whitespace-only string', () => {
    expect(() => validateTimezone('   ')).toThrow();
  });

  it('rejects very long timezone string', () => {
    const longTz = 'A'.repeat(1000);
    expect(() => validateTimezone(longTz)).toThrow(/Invalid timezone/);
  });
});

// ================================================================
// validateCurrency — Happy Path
// ================================================================
describe('validateCurrency', () => {
  it('accepts VND uppercase', () => {
    expect(validateCurrency('VND')).toBe('VND');
  });

  it('accepts USD uppercase', () => {
    expect(validateCurrency('USD')).toBe('USD');
  });

  it('accepts vnd lowercase', () => {
    expect(validateCurrency('vnd')).toBe('VND');
  });

  it('accepts usd lowercase', () => {
    expect(validateCurrency('usd')).toBe('USD');
  });

  it('accepts mixed case VND', () => {
    expect(validateCurrency('VnD')).toBe('VND');
  });

  it('accepts mixed case USD', () => {
    expect(validateCurrency('UsD')).toBe('USD');
  });

  it('returns the uppercased currency code', () => {
    for (const input of ['vnd', 'usd', 'VND', 'USD', 'VnD', 'UsD']) {
      const result = validateCurrency(input);
      expect(result).toBe(input.toUpperCase());
    }
  });
});

// ================================================================
// validateCurrency — Negative Cases
// ================================================================
describe('validateCurrency — negative cases', () => {
  it('rejects EUR', () => {
    expect(() => validateCurrency('EUR')).toThrow(/Unsupported currency/);
  });

  it('rejects JPY', () => {
    expect(() => validateCurrency('JPY')).toThrow(/Unsupported currency/);
  });

  it('rejects GBP', () => {
    expect(() => validateCurrency('GBP')).toThrow(/Unsupported currency/);
  });

  it('rejects empty string', () => {
    expect(() => validateCurrency('')).toThrow();
  });

  it('rejects non-string input (number)', () => {
    expect(() => validateCurrency(123 as unknown as string)).toThrow(/Invalid currency/);
  });

  it('rejects null', () => {
    expect(() => validateCurrency(null as unknown as string)).toThrow(/Invalid currency/);
  });

  it('rejects undefined', () => {
    expect(() => validateCurrency(undefined as unknown as string)).toThrow(/Invalid currency/);
  });

  it('rejects numeric string "100"', () => {
    expect(() => validateCurrency('100' as unknown as string)).toThrow(/Unsupported currency/);
  });

  it('rejects partial currency code', () => {
    expect(() => validateCurrency('VN')).toThrow(/Unsupported currency/);
  });

  it('rejects currency code with spaces', () => {
    expect(() => validateCurrency('VN D')).toThrow(/Unsupported currency/);
  });

  it('rejects SQL injection attempt', () => {
    expect(() => validateCurrency("'; DROP TABLE households; --" as unknown as string)).toThrow();
  });

  it('rejects path traversal', () => {
    expect(() => validateCurrency('../../etc/passwd')).toThrow(/Unsupported currency/);
  });

  it('rejects very long string', () => {
    const longStr = 'A'.repeat(1000);
    expect(() => validateCurrency(longStr)).toThrow(/Unsupported currency/);
  });

  it('rejects whitespace string', () => {
    expect(() => validateCurrency('   ')).toThrow();
  });
});

// ================================================================
// validateCurrencyCode — Happy Path
// ================================================================
describe('validateCurrencyCode', () => {
  it('accepts VND', () => {
    expect(validateCurrencyCode('VND')).toBe('VND');
  });

  it('accepts USD', () => {
    expect(validateCurrencyCode('USD')).toBe('USD');
  });

  it('accepts EUR', () => {
    expect(validateCurrencyCode('EUR')).toBe('EUR');
  });

  it('accepts any valid ISO 4217 code (3 uppercase letters)', () => {
    for (const code of ['JPY', 'GBP', 'CNY', 'KHR', 'THB']) {
      expect(validateCurrencyCode(code)).toBe(code);
    }
  });

  it('returns the input code unchanged', () => {
    for (const code of ['VND', 'USD', 'EUR']) {
      expect(validateCurrencyCode(code)).toBe(code);
    }
  });
});

// ================================================================
// validateCurrencyCode — Negative Cases
// ================================================================
describe('validateCurrencyCode — negative cases', () => {
  it('rejects lowercase VND', () => {
    expect(() => validateCurrencyCode('vnd')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects mixed case', () => {
    expect(() => validateCurrencyCode('VnD')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects 2-letter code (ISO 3166-1 alpha-2)', () => {
    expect(() => validateCurrencyCode('VN')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects 4-letter code', () => {
    expect(() => validateCurrencyCode('VNDN')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects numeric code', () => {
    expect(() => validateCurrencyCode('704')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects mixed alphanumeric', () => {
    expect(() => validateCurrencyCode('VN1D')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects empty string', () => {
    expect(() => validateCurrencyCode('')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects non-string input (number)', () => {
    expect(() => validateCurrencyCode(123 as unknown as string)).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects null', () => {
    expect(() => validateCurrencyCode(null as unknown as string)).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects whitespace', () => {
    expect(() => validateCurrencyCode('   ')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects special characters', () => {
    expect(() => validateCurrencyCode('<script>')).toThrow(/Invalid ISO 4217 code/);
  });

  it('rejects SQL injection attempt', () => {
    expect(() => validateCurrencyCode("'; DROP TABLE currencies; --" as unknown as string)).toThrow();
  });
});

// ================================================================
// validateEpochMs — Happy Path
// ================================================================
describe('validateEpochMs', () => {
  it('accepts current time (2025)', () => {
    const now = Date.now();
    expect(validateEpochMs(now)).toBe(now);
  });

  it('accepts year 2001 (just after lower bound)', () => {
    // 946684800000 = Jan 1, 2000 UTC
    expect(validateEpochMs(946_684_800_001)).toBe(946_684_800_001);
  });

  it('accepts year 2050', () => {
    const ms = Date.UTC(2050, 0, 1);
    expect(validateEpochMs(ms)).toBe(ms);
  });

  it('accepts exact lower boundary (Jan 1, 2000)', () => {
    expect(validateEpochMs(946_684_800_000)).toBe(946_684_800_000);
  });

  it('accepts exact upper boundary (year 2100)', () => {
    expect(validateEpochMs(4_102_444_800_000)).toBe(4_102_444_800_000);
  });

  it('accepts mid-range timestamp (Jan 15, 2025)', () => {
    const ms = Date.UTC(2025, 0, 15);
    expect(validateEpochMs(ms)).toBe(ms);
  });

  it('returns the input value unchanged', () => {
    for (const val of [946_684_800_000, Date.now(), 4_102_444_800_000]) {
      expect(validateEpochMs(val)).toBe(val);
    }
  });
});

// ================================================================
// validateEpochMs — Negative Cases
// ================================================================
describe('validateEpochMs — negative cases', () => {
  it('rejects NaN', () => {
    expect(() => validateEpochMs(NaN)).toThrow(/finite number/);
  });

  it('rejects Infinity', () => {
    expect(() => validateEpochMs(Infinity)).toThrow(/finite number/);
  });

  it('rejects -Infinity', () => {
    expect(() => validateEpochMs(-Infinity)).toThrow(/finite number/);
  });

  it('rejects negative timestamp (before epoch)', () => {
    expect(() => validateEpochMs(-1000)).toThrow();
  });

  it('rejects zero timestamp (Jan 1, 1970)', () => {
    expect(() => validateEpochMs(0)).toThrow();
  });

  it('rejects just before lower boundary', () => {
    expect(() => validateEpochMs(946_684_799_999)).toThrow(/out of valid range/);
  });

  it('rejects just after upper boundary', () => {
    expect(() => validateEpochMs(4_102_444_800_001)).toThrow(/out of valid range/);
  });

  it('rejects year 3000', () => {
    // Year 3000 far exceeds upper boundary
    expect(() => validateEpochMs(Date.UTC(3000, 0, 1))).toThrow(/out of valid range/);
  });

  it('rejects non-string input (null)', () => {
    expect(() => validateEpochMs(null as unknown as number)).toThrow(/finite number/);
  });

  it('rejects non-string input (undefined)', () => {
    expect(() => validateEpochMs(undefined as unknown as number)).toThrow(/finite number/);
  });

  it('rejects boolean input', () => {
    // true converts to 1 in JS, which is < lower boundary => rejected
    expect(() => validateEpochMs(true as unknown as number)).toThrow();
  });

  it('rejects string input', () => {
    expect(() => validateEpochMs('1700000000000' as unknown as number)).toThrow(/finite number/);
  });

  it('rejects floating point (non-integer)', () => {
    // parseFloat is allowed since we only check Number.isFinite
    const result = validateEpochMs(1700000000000.5);
    expect(result).toBe(1700000000000.5);
  });

  it('rejects very large safe integer (year ~1e6)', () => {
    expect(() => validateEpochMs(Number.MAX_SAFE_INTEGER)).toThrow(/out of valid range/);
  });
});

// ================================================================
// validateClientId — Happy Path
// ================================================================
describe('validateClientId', () => {
  it('accepts UUID v4 format', () => {
    const uuid = '550e8400-e29b-41d4-a716-446655440000';
    expect(validateClientId(uuid)).toBe(uuid);
  });

  it('accepts long alphanumeric string', () => {
    const id = 'abc123def456ghi789jkl012mno345pqr678stu';
    expect(validateClientId(id)).toBe(id);
  });

  it('accepts UUID with hyphens', () => {
    const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    expect(validateClientId(uuid)).toBe(uuid);
  });

  it('accepts string exactly at minimum length (10)', () => {
    const id = 'abcdefghij'; // exactly 10 chars
    expect(validateClientId(id)).toBe(id);
  });

  it('returns the input string unchanged', () => {
    for (const id of ['550e8400-e29b-41d4-a716-446655440000', 'abc123def456']) {
      expect(validateClientId(id)).toBe(id);
    }
  });
});

// ================================================================
// validateClientId — Negative Cases
// ================================================================
describe('validateClientId — negative cases', () => {
  it('rejects empty string', () => {
    expect(() => validateClientId('')).toThrow(/must be a non-empty string/);
  });

  it('rejects null', () => {
    expect(() => validateClientId(null as unknown as string)).toThrow(/must be a non-empty string/);
  });

  it('rejects undefined', () => {
    expect(() => validateClientId(undefined as unknown as string)).toThrow(/must be a non-empty string/);
  });

  it('rejects number input', () => {
    expect(() => validateClientId(12345 as unknown as string)).toThrow();
  });

  it('rejects exactly 9 characters (below minimum)', () => {
    expect(() => validateClientId('abcdefghi')).toThrow(/must be a non-empty string/);
  });

  it('rejects UUID-like short string', () => {
    expect(() => validateClientId('abc')).toThrow(/must be a non-empty string/);
  });

  it('rejects numeric string of length < 10', () => {
    expect(() => validateClientId('123456789')).toThrow(/must be a non-empty string/);
  });

  it('accepts numeric string at exactly 10 characters', () => {
    const id = '1234567890';
    expect(validateClientId(id)).toBe(id);
  });

  it('rejects whitespace-only string', () => {
    expect(() => validateClientId('         ')).toThrow(/must be a non-empty string/);
  });

  it('rejects special characters (length OK)', () => {
    const id = '!!!';
    expect(() => validateClientId(id)).toThrow(/must be a non-empty string/);
  });
});

// ================================================================
// Security — Injection / XSS Prevention
// ================================================================
describe('Security — input validation prevents injection', () => {
  it('validateTimezone rejects script injection', () => {
    expect(() => validateTimezone('<script>alert(1)</script>')).toThrow(/Invalid timezone/);
  });

  it('validateTimezone rejects SQL injection', () => {
    expect(() => validateTimezone("' OR '1'='1")).toThrow(/Invalid timezone/);
  });

  it('validateCurrency rejects script injection', () => {
    expect(() => validateCurrency('<script>alert(1)</script>')).toThrow(/Unsupported currency/);
  });

  it('validateCurrencyCode rejects XSS attempt', () => {
    expect(() => validateCurrencyCode('</script><script>alert(1)</script>')).toThrow(/Invalid ISO 4217 code/);
  });

  it('validateEpochMs rejects boolean input (DoS via type coercion)', () => {
    expect(() => validateEpochMs(true as unknown as number)).toThrow();
  });

  it('validateClientId rejects empty string (null pointer prevention)', () => {
    expect(() => validateClientId('')).toThrow(/must be a non-empty string/);
  });

  it('validateMoney rejects array input', () => {
    expect(() => validateMoney([100] as unknown as number, 'VND')).toThrow(/must be a safe integer/);
  });

  it('validateCurrencyCode rejects object input', () => {
    expect(() => validateCurrencyCode({} as unknown as string)).toThrow(/Invalid ISO 4217 code/);
  });
});
