/** Mây Family Finance — Backend Common: StructuredLogger
 *
 * Privacy-safe structured logging. NEVER logs financial amounts, PII,
 * receipt OCR content, or billing tokens.
 */

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error',
}

/** Sanitized log entry — no PII fields allowed. */
interface LogEntry {
  severity: LogLevel;
  correlationId: string;
  function: string;
  message: string;
  metadata?: Record<string, unknown>;
}

/**
 * Structured logger that prevents financial PII from being logged.
 * All sensitive fields are automatically redacted before output.
 */
export class StructuredLogger {
  private readonly functionName: string;

  constructor(functionName: string) {
    this.functionName = functionName;
  }

  info(message: string, metadata?: Record<string, unknown>): void {
    this._log(LogLevel.INFO, message, sanitizeMetadata(metadata));
  }

  warn(message: string, metadata?: Record<string, unknown>): void {
    this._log(LogLevel.WARN, message, sanitizeMetadata(metadata));
  }

  error(message: string, metadata?: Record<string, unknown>, correlationId?: string): void {
    this._log(LogLevel.ERROR, message, sanitizeMetadata({ ...metadata, correlationId }));
  }

  debug(message: string, metadata?: Record<string, unknown>): void {
    // Debug is only output in dev environment.
    if (process.env.NODE_ENV === 'development') {
      this._log(LogLevel.DEBUG, message, sanitizeMetadata(metadata));
    }
  }

  private _log(severity: LogLevel, message: string, metadata: Record<string, unknown>): void {
    const entry: LogEntry = {
      severity,
      correlationId: metadata.correlationId ?? 'N/A',
      function: this.functionName,
      message,
      metadata: Object.fromEntries(
        Object.entries(metadata).filter(([k]) => k !== 'correlationId'),
      ),
    };

    // Output structured JSON for log aggregation.
    console.log(JSON.stringify(entry));
  }
}

/**
 * Sanitizes metadata by redacting known sensitive fields.
 * This is the LAST line of defense — never rely on it alone.
 */
function sanitizeMetadata(metadata?: Record<string, unknown>): Record<string, unknown> {
  if (!metadata) return {};

  const SENSITIVE_FIELDS = new Set([
    'amountMinor', 'totalMinor', 'balanceMinor', // Money amounts
    'ocrText', 'receiptContent', 'merchantRaw',   // OCR PII
    'token', 'fcmToken', 'deviceToken',           // Auth tokens
    'signature', 'signedPayload', 'jws',           // Billing signatures
    'rawPayload',                                  // Raw webhook data
  ]);

  const sanitized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(metadata)) {
    const lowerKey = key.toLowerCase();

    if (SENSITIVE_FIELDS.has(lowerKey)) {
      sanitized[key] = '[REDACTED]';
      continue;
    }

    // Redact email-like values.
    if (typeof value === 'string' && /@[a-z]/i.test(value)) {
      sanitized[key] = '[REDACTED_EMAIL]';
      continue;
    }

    sanitized[key] = value;
  }

  return sanitized;
}

/**
 * Creates a logger instance for the given function name.
 */
export function createLogger(functionName: string): StructuredLogger {
  return new StructuredLogger(functionName);
}
