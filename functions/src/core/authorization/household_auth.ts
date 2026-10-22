/** Mây Family Finance — Backend Common: HouseholdAuthorization
 *
 * Server-side authorization that bypasses RTDB Security Rules via Admin SDK.
 * NEVER trusts client-provided role values. Always reads from /members/{hid}/{uid}.
 */

import { type AuthInfo } from '../auth/auth_context.js';
import { AppError, ErrorCode } from '../errors/app_error.js';
import * as admin from 'firebase-admin';

// Initialize Admin SDK — required before any household access check.
let _db: admin.database.Database | null = null;

function getDatabase(): admin.database.Database {
  if (!_db) {
    // Admin SDK must be initialized by the Functions runtime via
    // `admin.initializeApp()` or `initializeApp({ databaseURL: '...' })`.
    try {
      _db = admin.database();
    } catch (_) {
      throw new AppError(
        ErrorCode.TEMPORARY_UNAVAILABLE,
        'Firebase Admin not initialized',
        true,
      );
    }
  }
  return _db;
}

// -- Allowed roles for a given resource/action pair --

export type RoleRequirement = 'OWNER' | 'ADMIN' | 'EDITOR' | 'VIEWER' | 'MEMBER';

/** Member status values stored in /members/{hid}/{uid}/status */
enum MemberStatus {
  ACTIVE = 'ACTIVE',
  PENDING = 'PENDING',
  REMOVED = 'REMOVED',
}

/**
 * Checks if a user has the required role in a household.
 * Reads membership from /members/{hid}/{uid} via Admin SDK.
 */
export async function checkHouseholdAccess(
  auth: AuthInfo,
  householdId: string,
  requiredRole: RoleRequirement,
): Promise<boolean> {
  const memberRef = getDatabase()
    .ref(`members/${householdId}/${auth.uid}`);

  const snapshot = await memberRef.once('value');

  if (!snapshot.exists()) {
    return false; // No membership record — access denied.
  }

  const data = snapshot.val();
  const status = data?.status as string;
  const role = data?.role as string;

  // Must be ACTIVE member. PENDING/REMOVED are denied.
  if (status !== MemberStatus.ACTIVE) {
    return false;
  }

  // Check role hierarchy — member role must meet or exceed required role.
  return hasRequiredRole(role, requiredRole);
}

/**
 * Determines the minimum role needed for a resource/action.
 */
export function actionRequires(action: string): RoleRequirement {
  const writeActions = ['CREATE', 'UPDATE', 'DELETE'];
  if (writeActions.some((a) => action.includes(a))) return 'EDITOR';
  return 'VIEWER';
}

/**
 * Checks if a member's role meets the requirement.
 */
function hasRequiredRole(memberRole: string, requiredRole: RoleRequirement): boolean {
  const roleHierarchy: Record<RoleRequirement, number> = {
    OWNER: 3,
    ADMIN: 2,
    EDITOR: 1,
    VIEWER: 0,
    MEMBER: -1,
  };

  const memberLevel = roleHierarchy[memberRole as RoleRequirement] ?? -1;
  const requiredLevel = roleHierarchy[requiredRole];

  return memberLevel >= requiredLevel;
}

/**
 * Returns the authenticated user's role in a household, or null if not found.
 */
export async function getMemberRole(
  auth: AuthInfo,
  householdId: string,
): Promise<string | null> {
  const memberRef = getDatabase()
    .ref(`members/${householdId}/${auth.uid}`);

  const snapshot = await memberRef.once('value');

  if (!snapshot.exists()) {
    return null;
  }

  const data = snapshot.val();
  return data?.role as string | null;
}

/**
 * Validates that the current user is not removed from the household.
 */
export async function checkMemberActive(
  auth: AuthInfo,
  householdId: string,
): Promise<AppError | null> {
  const role = await getMemberRole(auth, householdId);

  if (role === null) {
    return new AppError(
      ErrorCode.HOUSEHOLD_ACCESS_DENIED,
      'Not a member of this household',
      false,
    );
  }

  // Additional check: verify status is ACTIVE via direct lookup.
  const statusRef = getDatabase()
    .ref(`members/${householdId}/${auth.uid}/status`);
  const snapshot = await statusRef.once('value');

  if (snapshot.val() !== MemberStatus.ACTIVE) {
    return new AppError(
      ErrorCode.HOUSEHOLD_ACCESS_DENIED,
      'Membership is not active',
      false,
    );
  }

  return null;
}

/**
 * Ensures the user is the owner of a household (or has ownership transfer rights).
 */
export async function checkOwner(
  auth: AuthInfo,
  householdId: string,
): Promise<AppError | null> {
  const role = await getMemberRole(auth, householdId);

  if (role !== 'OWNER') {
    return new AppError(
      ErrorCode.ROLE_DENIED,
      'Only the household owner can perform this action',
      false,
    );
  }

  return null;
}
