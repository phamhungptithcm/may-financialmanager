/** Mây Family Finance — Backend Common: HouseholdAuthorization
 *
 * Server-side authorization that bypasses RTDB Security Rules via Admin SDK.
 * NEVER trusts client-provided role values. Always reads from /members/{hid}/{uid}.
 */

import { getAuthInfo, type AuthInfo } from '../auth/auth_context.js';
import { AppError, ErrorCode } from '../errors/app_error.js';

/** Allowed roles for a given resource/action pair. */
export type RoleRequirement = 'OWNER' | 'ADMIN' | 'EDITOR' | 'VIEWER' | 'MEMBER';

/**
 * Checks if a user has the required role in a household.
 * Reads membership from /members/{hid}/{uid} via Admin SDK.
 */
export async function checkHouseholdAccess(
  auth: AuthInfo,
  householdId: string,
  requiredRole: RoleRequirement,
): Promise<boolean> {
  // MVP placeholder — actual implementation reads /members/{hid}/{uid} from RTDB.
  // The Firebase Admin SDK Firestore/RTDB client would be imported here.

  // In production:
  // const memberDoc = await admin.firestore().doc(`members/${householdId}/${auth.uid}`).get();
  // if (!memberDoc.exists) throw new AppError(ErrorCode.HOUSEHOLD_ACCESS_DENIED, ...);
  // const role = memberDoc.data()!.role;
  // return hasRequiredRole(role, requiredRole);

  return true; // Placeholder — remove when actual RTDB access is implemented.
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
 * Validates that the current user is not removed from the household.
 */
export async function checkMemberActive(
  auth: AuthInfo,
  householdId: string,
): Promise<AppError | null> {
  // MVP placeholder — actual implementation checks members/{hid}/{uid}/status === 'ACTIVE'
  return null;
}

/**
 * Ensures the user is the owner of a household (or has ownership transfer rights).
 */
export async function checkOwner(
  auth: AuthInfo,
  householdId: string,
): Promise<AppError | null> {
  // MVP placeholder — actual implementation checks members/{hid}/{uid}/role === 'OWNER'
  return null;
}
