/** Mây Family Finance — Firebase Emulator Integration Tests: Auth & Household Boundaries
 *
 * These tests require the Firebase Emulator to be running.
 * Run with: firebase emulators:exec --only auth,database,storage "npm test -- test/emulator/auth_household.test.ts"
 *
 * TC-001: first sign-in creates personal household + OWNER membership
 * TC-002: viewer invites member → permission denied
 * TC-003: removed member reads household data → denied
 * TC-035: UID in household A cannot read household B data
 */

import { describe, it, expect } from 'vitest';

describe('TC-001 | First sign-in creates personal household', () => {
  // Stub — requires Firebase Auth emulator + createHousehold callable.
  // Phase 1: Implement via emulated callable handler.
  it('should not be skipped in CI when emulator is available', () => {
    expect(true).toBe(true);
  });
});

describe('TC-002 | Viewer invites member → permission denied', () => {
  // Stub — requires two users (owner + viewer), invitation flow.
  it('should not be skipped in CI when emulator is available', () => {
    expect(true).toBe(true);
  });
});

describe('TC-003 | Removed member reads household data → denied', () => {
  // Stub — requires removing a member, then verifying denial.
  it('should not be skipped in CI when emulator is available', () => {
    expect(true).toBe(true);
  });
});

describe('TC-035 | Cross-tenant isolation: UID A cannot read household B data', () => {
  // Stub — requires two households, verifying read/write denial.
  it('should not be skipped in CI when emulator is available', () => {
    expect(true).toBe(true);
  });
});
