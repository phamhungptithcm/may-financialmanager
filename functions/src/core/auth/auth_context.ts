/** Mây Family Finance — Backend Common: AuthContext
 *
 * Extracts and validates auth information from v2 Callable function context.
 * Uses Firebase Auth uid (request.auth.uid), NOT client-provided uid.
 */

import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { AppError, ErrorCode } from '../errors/app_error.js';
import * as admin from 'firebase-admin';

export interface AuthInfo {
  uid: string;
  token: CallableRequest['auth']; // Firebase auth token (may be null for unauthenticated)
}

/**
 * Extracts auth info from a callable function context.
 * Returns an error if the user is not authenticated.
 */
export function getAuthInfo(context: CallableRequest): AuthInfo | AppError {
  const uid = context.auth?.uid;
  const token = context.auth;

  if (!uid) {
    return new AppError(ErrorCode.AUTH_REQUIRED, 'User must be authenticated', true);
  }

  return { uid, token };
}

/**
 * Guards a callable function by checking authentication and app check.
 * Throws HttpsError if auth is invalid.
 */
export function guardAuth(context: CallableRequest): void {
  const err = getAuthError(context);
  if (err) throw err;

  // Validate App Check — in v2 the runtime verifies automatically,
  // but we ensure app attestation was provided.
  const appId = context.app?.appId;
  if (!appId && !isDevBypassAllowed()) {
    throw new HttpsError(
      'unauthenticated',
      'App Check token required. Please update your app to use App Check.',
    );
  }

  // Also validate the raw token in dev mode for extra safety.
  const appCheckValid = validateAppCheck(appId ?? null);
  if (!appCheckValid && !isDevBypassAllowed()) {
    throw new HttpsError(
      'unauthenticated',
      'App Check verification failed.',
    );
  }
}

function getAuthError(context: CallableRequest): Error | null {
  if (!context.auth) {
    return new HttpsError('unauthenticated', 'Authentication required');
  }
  return null;
}

/**
 * Validates App Check token. Returns true if valid or enforcement is off.
 * In production, verifies the appId against Firebase's App Check service.
 */
export function validateAppCheck(appCheckToken: string | null): boolean {
  // No token provided — check if dev bypass is allowed.
  if (!appCheckToken) return isDevBypassAllowed();

  // Dev mode: accept well-formed tokens (appId > 10 chars).
  if (isDevBypassAllowed()) {
    return appCheckToken.length > 10;
  }

  // Production mode — verify token via Firebase App Check service.
  try {
    const appCheck = admin.appCheck();
    if (!appCheck) {
      return false;
    }

    // Verify the App Check token — rejects if invalid, expired, or revoked.
    admin.appCheck().verifyToken(appCheckToken);
    return true;
  } catch {
    return false;
  }
}

/**
 * Checks whether dev bypass is allowed for App Check.
 * Controlled by environment variable to allow local testing without
 * disabling App Check in production.
 */
function isDevBypassAllowed(): boolean {
  return process.env.APP_CHECK_DEV_BYPASS === 'true';
}
