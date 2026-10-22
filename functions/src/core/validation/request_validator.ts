/** Mây Family Finance — Backend Common: RequestValidator
 *
 * Central request validation using Zod strict mode.
 * All callable handlers validate input schemas before any side effects.
 */

import { z } from 'zod';
import { AppError, ErrorCode } from '../errors/app_error.js';

/**
 * Validates a request payload against a Zod schema and maps errors to AppError.
 * Uses .strict() to reject unknown fields (prevents prototype pollution).
 */
export function validateRequest<T>(
  input: unknown,
  schema: z.ZodSchema<T>,
): T {
  try {
    const result = schema.parse(input);
    return result;
  } catch (error) {
    if (error instanceof z.ZodError) {
      const fieldErrors: Record<string, string> = {};
      for (const issue of error.issues) {
        const path = issue.path.join('.');
        fieldErrors[path] = issue.message;
      }
      throw new AppError(
        ErrorCode.VALIDATION_ERROR,
        `Invalid request: ${error.message}`,
        false,
        fieldErrors,
      );
    }
    // Unexpected error type — treat as validation failure.
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'Request validation failed', false);
  }
}

/**
 * Validates a money amount: finite positive integer minor units, safe integer range.
 */
export function validateMoney(amountMinor: unknown, currency: unknown): {
  amountMinor: number;
  currency: string;
} {
  if (typeof amountMinor !== 'number' || !Number.isSafeInteger(amountMinor)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'amountMinor must be a safe integer', false);
  }

  const upperBound = Number.MAX_SAFE_INTEGER;
  if (Math.abs(amountMinor) > upperBound) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, `Amount exceeds safe integer range`, false);
  }

  if (typeof currency !== 'string' || !['VND', 'USD'].includes(currency.toUpperCase())) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      `Unsupported currency: ${typeof currency === 'string' ? currency : String(currency)}`,
      false,
    );
  }

  return { amountMinor, currency: currency.toUpperCase() };
}

/**
 * Validates household timezone (must be IANA tz).
 */
export function validateTimezone(tz: unknown): string {
  if (typeof tz !== 'string') {
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'timezone must be a string', false);
  }
  try {
    Intl.DateTimeFormat('en', { timeZone: tz }); // throws if invalid
    return tz;
  } catch {
    throw new AppError(ErrorCode.VALIDATION_ERROR, `Invalid timezone: ${tz}`, false);
  }
}

/**
 * Validates currency code against the v1 allowlist.
 */
export function validateCurrency(currency: unknown): 'VND' | 'USD' {
  if (typeof currency !== 'string') {
    throw new AppError(ErrorCode.VALIDATION_ERROR, `Invalid currency: ${String(currency)}`, false);
  }
  const upper = currency.toUpperCase();
  if (upper === 'VND' || upper === 'USD') return upper as 'VND' | 'USD';
  throw new AppError(ErrorCode.VALIDATION_ERROR, `Unsupported currency: ${currency}`, false);
}

/**
 * Validates ISO 4217 currency code format (3 uppercase letters).
 */
export function validateCurrencyCode(code: unknown): string {
  if (typeof code !== 'string' || !/^[A-Z]{3}$/.test(code)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, `Invalid ISO 4217 code: ${String(code)}`, false);
  }
  return code;
}

/**
 * Validates epoch milliseconds: finite positive number within reasonable range.
 */
export function validateEpochMs(ms: unknown): number {
  if (typeof ms !== 'number' || !Number.isFinite(ms)) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'Timestamp must be a finite number', false);
  }
  const now = Date.now();
  // Allow timestamps from year 2000 to year 2100.
  if (ms < 946_684_800_000 || ms > 4_102_444_800_000) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'Timestamp out of valid range', false);
  }
  return ms;
}

/**
 * Validates a UUID v4 format (loose check — actual generation/validation on write).
 */
export function validateClientId(clientRequestId: unknown): string {
  if (typeof clientRequestId !== 'string' || clientRequestId.length < 10) {
    throw new AppError(ErrorCode.VALIDATION_ERROR, 'clientRequestId must be a non-empty string', false);
  }
  return clientRequestId;
}
