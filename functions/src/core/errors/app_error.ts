/** Mây Family Finance — Backend Common: AppError + ErrorCode
 *
 * Consistent error model across all Cloud Functions.
 * Errors are sanitized before returning to the client (no PII leakage).
 */

export enum ErrorCode {
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  HOUSEHOLD_ACCESS_DENIED = 'HOUSEHOLD_ACCESS_DENIED',
  ROLE_DENIED = 'ROLE_DENIED',
  ACCOUNT_NOT_FOUND = 'ACCOUNT_NOT_FOUND',
  CURRENCY_MISMATCH = 'CURRENCY_MISMATCH',
  DUPLICATE_CONFLICT = 'DUPLICATE_CONFLICT',
  ALREADY_REVERSED = 'ALREADY_REVERSED',
  RECEIPT_NOT_READY = 'RECEIPT_NOT_READY',
  PURCHASE_UNVERIFIED = 'PURCHASE_UNVERIFIED',
  RATE_LIMITED = 'RATE_LIMITED',
  TEMPORARY_UNAVAILABLE = 'TEMPORARY_UNAVAILABLE',
  INVARIANT_FAILED = 'INVARIANT_FAILED',
}

/**
 * Typed application error with stable error code for client mapping.
 */
export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly correlationId: string;
  public readonly fieldErrors?: Record<string, string>;
  public readonly retryable: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    retryable = false,
    fieldErrors?: Record<string, string>,
  ) {
    super(sanitizeMessage(message));
    this.code = code;
    this.correlationId = generateCorrelationId();
    this.retryable = retryable;
    this.fieldErrors = fieldErrors;
    Object.setPrototypeOf(this, AppError.prototype);
  }

  /** Maps to HttpsError detail code for callable functions. */
  toHttpsErrorDetail(): { code: string; details: unknown } {
    return {
      code: [
        ErrorCode.ACCOUNT_NOT_FOUND,
        ErrorCode.RECEIPT_NOT_READY,
        ErrorCode.PURCHASE_UNVERIFIED,
      ].includes(this.code)
        ? 'failed-precondition'
        : this.code === ErrorCode.AUTH_REQUIRED
          ? 'unauthenticated'
          : this.code === ErrorCode.HOUSEHOLD_ACCESS_DENIED || this.code === ErrorCode.ROLE_DENIED
            ? 'permission-denied'
            : this.code === ErrorCode.DUPLICATE_CONFLICT
              ? 'already-exists'
              : 'invalid-argument',
      details: {
        fieldErrors: this.fieldErrors,
        correlationId: this.correlationId,
      },
    };
  }
}

// -- Helpers --

let _correlationCounter = Date.now();

function generateCorrelationId(): string {
  const ts = Date.now();
  if (ts !== _correlationCounter) {
    _correlationCounter = ts;
  }
  return `corr_${ts}_${Math.random().toString(36).substring(2, 8)}`;
}

/**
 * Sanitizes error messages to prevent PII leakage.
 * Redacts emails, phone numbers, bank numbers, and financial amounts.
 */
function sanitizeMessage(msg: string): string {
  let sanitized = msg;

  // Remove email addresses.
  sanitized = sanitized.replace(/[^\s@]+@[^\s@]+\.[^\s@]+/g, '[REDACTED_EMAIL]');

  // Remove phone numbers (Vietnamese format).
  sanitized = sanitized.replace(/(\+84|0)(3|5|7|8|9)\d{8}/g, '[REDACTED_PHONE]');

  // Remove potential credit card / bank account numbers.
  sanitized = sanitized.replace(/\b\d{12,}\b/g, '[REDACTED_NUMBER]');

  // Remove financial amounts (e.g., "185,000 VND", "$1,850.00", "999,000 USD").
  sanitized = sanitized.replace(
    /\b\d{1,3}(?:,\d{3})+(?= VND| USD| EUR| £|\b)/gi,
    '[REDACTED_AMOUNT]',
  );

  return sanitized;
}
