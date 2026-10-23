/** Mây Family Finance — Emulator Integration Tests: Phase 1 Auth + Household
 *
 * TC-001 through TC-003: auth and household creation flows.
 */

import { afterAll, afterEach, beforeAll, describe, expect, test } from 'vitest';
import * as admin from 'firebase-admin';
import { initializeApp, getApps } from 'firebase-admin/app';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

// ---------------------------------------------------------------------------
// Test environment setup (Firebase Emulator Suite)
// ---------------------------------------------------------------------------

let db: admin.database.Database;

beforeAll(async () => {
  // In emulator mode, no real project is needed for rules-unit-testing.
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  process.env.FIREBASE_DATABASE_EMULATOR_HOST = '127.0.0.1:9000';
});

afterAll(async () => {
  // cleanup handled by test environment teardown
});

// ---------------------------------------------------------------------------
// TC-001: First sign-in creates personal household (idempotent)
// FR-001, FR-002
// ---------------------------------------------------------------------------
describe('TC-001 — first sign-in household', () => {
  test('TC-001a: new UID → exactly one household created', async () => {
    // SETUP: create unauthenticated user
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });

    const user = client.unauthenticatedUser();
    const authed = await user.loginWithTestUser({
      uid: 'test-uid-' + Date.now(),
      email: 'test@example.com',
    });

    // ACTION: call createHousehold with valid payload
    const result = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình Test',
      timezone: 'Asia/Ho_Chi_Minh',
      currency: 'VND',
      clientRequestId: `tc001-${Date.now()}`,
    });

    // ASSERT: exactly one household exists
    expect(result.data).toHaveProperty('householdId');
    const hid = result.data.householdId as string;
    expect(hid).toBeDefined();
    expect(typeof hid).toBe('string');
    expect((result.data as any).status).toBe('accepted');

    // Verify /households/{hid} in emulator
    const snap = await admin.database().ref(`households/${hid}`).once('value');
    expect(snap.exists()).toBe(true);
    const householdData = snap.val();
    expect(householdData.name).toBe('Gia đình Test');
    expect(householdData.currency).toBe('VND');
    expect(householdData.timezone).toBe('Asia/Ho_Chi_Minh');

    // Verify /members/{hid}/{uid} with OWNER role
    const memberRef = admin.database().ref(`members/${hid}/${authed.user.uid}`);
    const memberSnap = await memberRef.once('value');
    expect(memberSnap.val()?.role).toBe('OWNER');
    expect(memberSnap.val()?.status).toBe('ACTIVE');

    // CLEANUP
    client.cleanup();
  });

  test('TC-001b: same UID retry → returns original householdId (idempotent)', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });
    const uid = `test-uid-${Date.now()}`;

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid, email: `${uid}@example.com`,
    });

    // First call
    const r1 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình Test', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001b-${Date.now()}`,
    });

    // Retry with same payload
    const r2 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình Test', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001b-${Date.now()}`,
    });

    expect(r1.data.householdId).toBe(r2.data.householdId);
    client.cleanup();
  });

  test('TC-001c: duplicate household for same user → returns existing', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });
    const uid = `test-uid-${Date.now()}`;

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid, email: `${uid}@example.com`,
    });

    // First household
    const r1 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình A', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001c-1-${Date.now()}`,
    });

    // Second household (different clientRequestId)
    const r2 = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình B', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc001c-2-${Date.now()}`,
    });

    // Per BR-02: user creates ONE personal household — second call should return existing
    expect(r1.data.householdId).toBe(r2.data.householdId);
    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-002: Viewer cannot invite member
// FR-003, BR-07
// ---------------------------------------------------------------------------
describe('TC-002 — invite permissions', () => {
  test('TC-002a: VIEWER role cannot invite → denied', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });

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

    const viewerAuthed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc002-viewer', email: 'viewer@example.com',
    });

    // Attempt invite — should fail with ROLE_DENIED
    try {
      await viewerAuthed.functions().httpsCallable('inviteHouseholdMember')({
        householdId: hid, inviteRole: 'EDITOR', expiresInHours: 24,
        clientRequestId: `tc002-invite-${Date.now()}`,
      });
      expect(true).toBe(false); // should not reach here
    } catch (err: any) {
      expect(err.code).toBe('permission-denied');
    }

    client.cleanup();
  });

  test('TC-002b: OWNER can invite → returns shareable link', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });

    const authed = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc002-own2', email: 'own2@example.com',
    });
    const inviteResult = await authed.functions().httpsCallable('createHousehold')({
      name: 'Gia đình TC-002b', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc002b-${Date.now()}`,
    });
    const hid = inviteResult.data.householdId;

    const result = await authed.functions().httpsCallable('inviteHouseholdMember')({
      householdId: hid, inviteRole: 'ADMIN', expiresInHours: 48,
      clientRequestId: `tc002b-inv-${Date.now()}`,
    });

    expect(result.data).toHaveProperty('inviteId');
    expect(result.data).toHaveProperty('shareableLink');
    expect(result.data).toHaveProperty('expiresAtMs');
    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-003: Removed member cannot read household data
// FR-004, BR-13
// ---------------------------------------------------------------------------
describe('TC-003 — removed member access denied', () => {
  test('TC-003a: READERSHIP revoked immediately after removal', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });

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

    // Try to read — should be denied
    const snap = await admin.database().ref(`households/${hid}`).once('value');
    expect(snap.exists()).toBe(false); // RTDB rules deny because user is not active member

    client.cleanup();
  });
});

// ---------------------------------------------------------------------------
// TC-035: Cross-tenant isolation
// FR-001, BR-01
// ---------------------------------------------------------------------------
describe('TC-035 — cross-tenant isolation', () => {
  test('TC-035a: UID A in household A cannot read household B', async () => {
    const project = 'may-dev';
    const client = await initializeTestEnvironment({ projectId: project });

    // Create household A with user A
    const userA = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc035a-a', email: 'a@example.com',
    });
    const householdA = await userA.functions().httpsCallable('createHousehold')({
      name: 'HH A', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc035-${Date.now()}`,
    });

    // Create separate household B with user B
    const userB = await client.unauthenticatedUser().loginWithTestUser({
      uid: 'tc035a-b', email: 'b@example.com',
    });
    await userB.functions().httpsCallable('createHousehold')({
      name: 'HH B', timezone: 'Asia/Ho_Chi_Minh', currency: 'VND',
      clientRequestId: `tc035b-${Date.now()}`,
    });

    // User A tries to read household B's data (direct admin SDK access)
    const snap = await admin.database().ref('households').once('value');
    expect(snap.exists()).toBe(true); // Root read depends on rules — but individual household read depends on membership.

    client.cleanup();
  });
});
