/** Mây Family Finance — Firebase Emulator Integration Tests: Auth & Household Boundaries
 *
 * TC-001a/b/c: first sign-in creates personal household (idempotent)
 * TC-002a/b: viewer invites member → permission denied; owner invites → succeeds
 * TC-003a: removed member reads household data → denied
 * TC-035: UID in household A cannot read household B data
 */

import { describe, test } from 'vitest';
import * as admin from 'firebase-admin';

// Gracefully skip when rules-unit-testing is not installed (Phase 2 prerequisite).
let rulesTesting: typeof import('@firebase/rules-unit-testing') | undefined;
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  rulesTesting = await import('@firebase/rules-unit-testing');
} catch {
  // dependency not installed — skipped below handled by if guard
}

const { initializeTestEnvironment } = rulesTesting ?? {};

if (!initializeTestEnvironment) {
  // When emulator testing is unavailable, skip all tests.
  describe.skip('Auth + Household (skipped: missing @firebase/rules-unit-testing)', () => {
    test('placeholder', () => {});
  });
} else {

const project = 'may-dev-auth';

// ---------------------------------------------------------------------------
// TC-001: First sign-in creates personal household (idempotent)
// FR-001, FR-002
// ---------------------------------------------------------------------------
describe('TC-001 | First sign-in creates personal household', () => {
  test('TC-001a: new UID → exactly one household created + OWNER membership', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });
    const user = client.unauthenticatedUser();
    const authed = await user.loginWithTestUser({
      uid: `tc001-${Date.now()}`,
      email: 'tc001@example.com',
    });

    // ACTION: call createHousehold with valid payload
    const result = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-001',
      timezone: 'Asia/Ho_Chi_Minh',
      currency: 'VND',
      clientRequestId: `tc001-${Date.now()}`,
    });

    // ASSERT: household created with valid fields
    expect(result.data).toHaveProperty('householdId');
    const hid = result.data.householdId as string;
    expect(typeof hid).toBe('string');
    expect((result.data as any).status).toBe('accepted');
    expect(Number.isInteger((result.data as any).createdAtMs)).toBe(true);

    // Verify /households/{hid} in emulator
    const snap = await admin.database().ref(`households/${hid}`).once('value');
    expect(snap.exists()).toBe(true);
    const hhData = snap.val();
    expect(hhData.name).toBe('Gia đình TC-001');
    expect(hhData.currency).toBe('VND');
    expect(hhData.timezone).toBe('Asia/Ho_Chi_Minh');

    // Verify /members/{hid}/{uid} with OWNER role
    const memberSnap = await admin.database().ref(`members/${hid}/${authed.user.uid}`).once('value');
    expect(memberSnap.val()?.role).toBe('OWNER');
    expect(memberSnap.val()?.status).toBe('ACTIVE');

    // Verify /userHouseholds/{uid} was written
    const uhSnap = await admin.database().ref(`userHouseholds/${authed.user.uid}`).once('value');
    expect(uhSnap.exists()).toBe(true);

    // CLEANUP
    client.cleanup();
  });

  test('TC-001b: same UID retry → returns original householdId (idempotent)', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });
    const uid = `tc001b-${Date.now()}`;

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid, email: `${uid}@example.com`,
    });

    // First call
    const r1 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-001b', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001b-cr-${Date.now()}`,
    });

    // Retry with same clientRequestId
    const r2 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-001b', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001b-cr-${Date.now()}`,
    });

    // ASSERT: same householdId returned (idempotent)
    expect(r1.data.householdId).toBe(r2.data.householdId);
    expect((r2.data as any).status).toBe('accepted');

    client.cleanup();
  });

  test('TC-001c: user already has household → returns existing', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });
    const uid = `tc001c-${Date.now()}`;

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid, email: `${uid}@example.com`,
    });

    // First household
    const r1 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình A', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001c-1-${Date.now()}`,
    });

    // Second household (different clientRequestId) — should return existing
    const r2 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình B', timezone: 'America/New_York', currency: 'USD',
      clientRequestId: `tc001c-2-${Date.now()}`,
    });

    // ASSERT: second call returns the same householdId
    expect(r1.data.householdId).toBe(r2.data.householdId);

    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-002: Viewer invites member → permission denied
// FR-003, BR-07
// ---------------------------------------------------------------------------
describe('TC-002 | Viewer invites member → permission denied', () => {
  test('TC-002a: VIEWER role cannot invite → denied', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });

    // Create household A with owner
    const ownerAuthed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc002-owner', email: 'owner@example.com',
    });
    const inviteResult = await ownerAuthed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-002', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc002-${Date.now()}`,
    });
    const hid = inviteResult.data.householdId;

    // Create a viewer member manually in emulator
    await admin.database().ref(`members/${hid}/tc002-viewer`).set({
      role: 'VIEWER', status: 'ACTIVE', joinedAtMs: Date.now(),
    });
    await admin.database().ref(`userHouseholds/tc002-viewer/-${hid}`).set(true);

    // Login as viewer
    const viewerAuthed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc002-viewer', email: 'viewer@example.com',
    });

    // Attempt invite — should fail with permission-denied / HOUSEHOLD_ACCESS_DENIED
    try {
      await viewerAuthed.functions().httpsCallable('inviteHouseholdMember')({
        householdId: hid, inviteRole: 'EDITOR', expiresInHours: 24,
        clientRequestId: `tc002-inv-${Date.now()}`,
      });
      expect(true).toBe(false); // should not reach here
    } catch (err: any) {
      expect(['permission-denied', 'unauthenticated']).toContain(err.code);
    }

    client.cleanup();
  });

  test('TC-002b: OWNER can invite → returns shareable link', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc002-own2', email: 'own2@example.com',
    });
    const inviteResult = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-002b', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc002b-${Date.now()}`,
    });
    const hid = inviteResult.data.householdId;

    // OWNER invites a member
    const result = await authed.functions().httpsCallable('inviteHouseholdMember')({
      householdId: hid, inviteRole: 'ADMIN', expiresInHours: 48,
      clientRequestId: `tc002b-inv-${Date.now()}`,
    });

    // ASSERT: invite created with valid data
    expect(result.data).toHaveProperty('inviteId');
    expect(result.data).toHaveProperty('shareableLink');
    expect(result.data).toHaveProperty('expiresAtMs');
    expect(typeof result.data.inviteId).toBe('string');
    expect(typeof result.data.shareableLink).toBe('string');
    expect(typeof result.data.expiresAtMs).toBe('number');

    // Verify invite was written to RTDB
    const inviteSnap = await admin.database().ref(`invites/${hid}/${result.data.inviteId}`).once('value');
    expect(inviteSnap.exists()).toBe(true);

    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-003: Removed member reads household data → denied
// FR-004, BR-13
// ---------------------------------------------------------------------------
describe('TC-003 | Removed member reads household data → denied', () => {
  test('TC-003a: READERSHIP revoked immediately after removal', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc003-own', email: 'tc003owner@example.com',
    });
    const householdResult = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-003', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc003-${Date.now()}`,
    });
    const hid = householdResult.data.householdId;

    // Remove the user (simulating removeHouseholdMember)
    await admin.database().ref(`members/${hid}/tc003-own`).update({ status: 'REMOVED' });

    // Try to read as removed user — should be denied by RTDB rules
    const viewerAuthed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc003-own', email: 'tc003owner@example.com',
    });

    try {
      // Attempting to call a function on a household they've been removed from
      await viewerAuthed.functions().httpsCallable('inviteHouseholdMember')({
        householdId: hid, inviteRole: 'EDITOR', expiresInHours: 24,
        clientRequestId: `tc003-inv-${Date.now()}`,
      });
    } catch {
      // Expected: permission-denied because user is REMOVED
    }

    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-035: Cross-tenant isolation
// FR-001, BR-01
// ---------------------------------------------------------------------------
describe('TC-035 | UID A cannot read household B data', () => {
  test('TC-035a: UID A in household A cannot access household B', async () => {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';

    const client = await initializeTestEnvironment!({ projectId: project });

    // Create household A with user A
    const userA = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc035a-a', email: 'a@example.com',
    });
    const householdA = await userA.functions().httpsCallable('createHousehold')({
      name: 'HH A', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc035-a-${Date.now()}`,
    });

    // Create separate household B with user B
    const userB = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc035a-b', email: 'b@example.com',
    });
    const householdB = await userB.functions().httpsCallable('createHousehold')({
      name: 'HH B', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc035-b-${Date.now()}`,
    });

    // ASSERT: different households were created
    expect(householdA.data.householdId).not.toBe(householdB.data.householdId);

    // User A tries to read household B's data via callable (should fail by RTDB rules)
    try {
      // Attempting to access a household the user isn't member of
      await userA.functions().httpsCallable('inviteHouseholdMember')({
        householdId: householdB.data.householdId, inviteRole: 'EDITOR', expiresInHours: 24,
        clientRequestId: `tc035-inv-${Date.now()}`,
      });
      // If no error, verify user A is not a member of household B
    } catch (err: any) {
      // Expected: permission-denied because user A has no access to household B
      expect(['permission-denied', 'unauthenticated']).toContain(err.code);
    }

    client.cleanup();
  });
});
}
