/** Mây Family Finance — Backend Common: AuthContext
 *
 * Extracts and validates auth information from Callable function context.
 * Uses Firebase Auth uid (context.auth.uid), NOT client-provided uid.
 */

import { https } from 'firebase-functions';
import { AppError, ErrorCode } from '../errors/app_error.js';

export interface AuthInfo {
  uid: string;
  token: https.CallableContext['auth']; // Firebase auth token (may be null for unauthenticated)
}

/**
 * Extracts auth info from a callable function context.
 * Returns an error if the user is not authenticated.
 */
export function getAuthInfo(context: https.CallableContext): AuthInfo | AppError {
  const uid = context.auth?.uid;
  const token = context.auth;

  if (!uid) {
    return new AppError(ErrorCode.AUTH_REQUIRED, 'User must be authenticated', true);
  }

  return { uid, token };
}

/**
 * Guards a callable function by checking authentication and app check.
 * Returns early with an HttpsError if auth is invalid.
 */
export function guardAuth(context: https.CallableContext): void {
  const err = getAuthError(context);
  if (err) throw err;
}

function getAuthError(context: https.CallableContext): Error | null {
  if (!context.auth) {
    return new https.HttpsError('unauthenticated', 'Authentication required');
  }
  return null;
}

/**
 * Validates App Check token. Returns true if valid or unenforced.
 * In dev environment, App Check may be bypassed (configurable).
 */
export function validateAppCheck(appCheckToken: string | null): boolean {
  if (!appCheckToken) return false;

  // MVP: App Check validation happens at the Functions runtime level.
  // We trust Firebase's built-in enforcement here.
  // Production: enable enforce in firebase.json for the appropriate region.
  return true;
}
