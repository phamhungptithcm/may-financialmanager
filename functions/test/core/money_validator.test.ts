/** Mây Family Finance — Tests: MoneyValidator
 *
 * Verified invariants per BR-03 (specs/01):
 * - safe integer amounts only
 * - positive for EXPENSE/INCOME/TRANSFER
 * - zero-sum postings
 * - currency consistency
 */

import { describe, it, expect } from 'vitest';
import {
  validateMoneyAmount,
  validatePostingBalance,
  validatePostingsCurrency,
  normalizeTransfer,
} from '../../src/core/money/money_validator.js';

describe('validateMoneyAmount', () => {
  it('accepts positive safe integer for EXPENSE', () => {
    expect(validateMoneyAmount(185000, 'EXPENSE')).toBe(185000);
  });

  it('rejects zero amount for EXPENSE', () => {
    expect(() => validateMoneyAmount(0, 'EXPENSE')).toThrow(
      /amountMinor must be > 0/,
    );
  });

  it('rejects negative amount for INCOME', () => {
    expect(() => validateMoneyAmount(-500, 'INCOME')).toThrow(
      /amountMinor must be > 0/,
    );
  });

  it('rejects floating point for TRANSFER', () => {
    expect(() => validateMoneyAmount(1.5, 'TRANSFER')).toThrow(
      /must be a safe integer/,
    );
  });

  it('accepts positive transfer amount', () => {
    expect(validateMoneyAmount(500000, 'TRANSFER')).toBe(500000);
  });
});

describe('validatePostingBalance', () => {
  it('passes when postings sum to zero', () => {
    const postings = {
      acct1: { deltaMinor: -185000 },
      acct2: { deltaMinor: 185000 },
    };
    expect(() => validatePostingBalance(postings)).not.toThrow();
  });

  it('rejects when postings do not sum to zero', () => {
    const postings = {
      acct1: { deltaMinor: -185000 },
      acct2: { deltaMinor: 184000 },
    };
    expect(() => validatePostingBalance(postings)).toThrow(
      /Posting balance invariant violated/,
    );
  });

  it('rejects positive-only postings', () => {
    const postings = {
      acct1: { deltaMinor: 100 },
      acct2: { deltaMinor: 100 },
    };
    expect(() => validatePostingBalance(postings)).toThrow(
      /Posting balance invariant violated/,
    );
  });
});

describe('validatePostingsCurrency', () => {
  it('passes when all postings match expected currency', () => {
    const postings = {
      acct1: { deltaMinor: -100, currency: 'VND' },
      acct2: { deltaMinor: 100, currency: 'VND' },
    };
    expect(() => validatePostingsCurrency(postings, 'VND')).not.toThrow();
  });

  it('rejects when postings have mismatched currency', () => {
    const postings = {
      acct1: { deltaMinor: -100, currency: 'VND' },
      acct2: { deltaMinor: 100, currency: 'USD' },
    };
    expect(() => validatePostingsCurrency(postings, 'VND')).toThrow(
      /Currency mismatch/,
    );
  });

  it('accepts postings without explicit currency field', () => {
    const postings = {
      acct1: { deltaMinor: -100 },
      acct2: { deltaMinor: 100 },
    };
    expect(() => validatePostingsCurrency(postings, 'VND')).not.toThrow();
  });
});

describe('normalizeTransfer', () => {
  it('produces correct signed deltas for equal magnitude', () => {
    const result = normalizeTransfer(500000, -500000);
    expect(result).toEqual({ fromDelta: -500000, toDelta: 500000 });
  });

  it('rejects unequal magnitudes', () => {
    expect(() => normalizeTransfer(500000, -499000)).toThrow(
      /must be equal magnitude/,
    );
  });
});
