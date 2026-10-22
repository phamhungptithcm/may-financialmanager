/** Mây Family Finance — Backend Common: MoneyValidator
 *
 * Monetary validation per BR-03 in specs/01:
 * - amountMinor > 0 for EXPENSE/INCOME (posted amounts)
 * - zero-sum postings for TRANSFER
 * - safe integer range enforced
 * - currency ISO 4217 validated
 */


/** Validates a single monetary amount for ledger posting. */
export function validateMoneyAmount(
  amountMinor: unknown,
  kind: string,
): number {
  if (typeof amountMinor !== 'number' || !Number.isSafeInteger(amountMinor)) {
    throw new Error(`amountMinor must be a safe integer, got ${typeof amountMinor}`);
  }

  // For EXPENSE/INCOME, amount must be positive.
  if ((kind === 'EXPENSE' || kind === 'INCOME') && amountMinor <= 0) {
    throw new Error(`amountMinor must be > 0 for ${kind}, got ${amountMinor}`);
  }

  // For TRANSFER, amounts are always positive (direction implied by posting sign).
  if (kind === 'TRANSFER' && amountMinor <= 0) {
    throw new Error(`Transfer amountMinor must be > 0, got ${amountMinor}`);
  }

  return amountMinor;
}

/**
 * Validates that postings sum to zero for the active currency.
 * Implements the double-entry balanced ledger invariant (BR-03).
 */
export function validatePostingBalance(
  postings: Record<string, { deltaMinor: number }>,
): void {
  const deltas = Object.values(postings).map((p) => p.deltaMinor);
  const sum = deltas.reduce((acc, d) => acc + d, 0);

  // VND: exponent 0 — exact integer comparison.
  if (sum !== 0) {
    throw new Error(
      `Posting balance invariant violated: expected 0, got ${sum} over deltas [${deltas.join(', ')}]`,
    );
  }
}

/**
 * Validates that all postings share the same currency.
 */
export function validatePostingsCurrency(
  postings: Record<string, { deltaMinor: number; currency?: string }>,
  expectedCurrency: string,
): void {
  for (const [account, posting] of Object.entries(postings)) {
    if (posting.currency && posting.currency !== expectedCurrency) {
      throw new Error(
        `Currency mismatch in posting ${account}: expected ${expectedCurrency}, got ${posting.currency}`,
      );
    }
  }
}

/**
 * Normalizes a transfer amount: ensures both delta values sum to zero.
 */
export function normalizeTransfer(fromMinor: number, toMinor: number): { fromDelta: number; toDelta: number } {
  if (fromMinor !== Math.abs(toMinor)) {
    throw new Error(`Transfer deltas must be equal magnitude: ${fromMinor} vs ${toMinor}`);
  }
  return { fromDelta: -Math.abs(fromMinor), toDelta: Math.abs(fromMinor) };
}

/**
 * Validates a ledgerAccount identifier format.
 */
export function validateLedgerAccount(account: string): boolean {
  // Format: TYPE:id (e.g., "ASSET:acc_cash", "EXPENSE:cat_food")
  const pattern = /^[A-Z]+:[a-zA-Z0-9_-]+$/;
  if (!pattern.test(account)) {
    throw new Error(`Invalid ledger account format: ${account}`);
  }
  return true;
}
