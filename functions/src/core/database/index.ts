/** Mây Family Finance — Backend Common: RTDB Utilities
 *
 * Provides RTDB read/write operations that work in both the real Admin SDK
 * and the Firebase Functions emulator stub (which does not expose admin.database()).
 */

import * as admin from 'firebase-admin';

let _db: ReturnType<typeof admin.database> | null = null;

/** Initialize or return existing database instance. Throws if unavailable. */
export function getDatabase(): ReturnType<typeof admin.database> {
  if (_db) return _db;

  const internal = admin as unknown as {
    apps: admin.app.App[];
    initializeApp(
      options?: { databaseURL?: string },
      name?: string,
    ): admin.app.App;
    database(): ReturnType<typeof admin.database>;
  };
  const apps = internal.apps ?? [];
  if (!apps.length) {
    const dbUrl = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
    if (dbUrl) {
      const [host, port] = dbUrl.split(':');
      internal.initializeApp({ databaseURL: `http://${host}:${port}` });
    } else {
      internal.initializeApp();
    }
  }

  try {
    _db = admin.database();
  } catch {
    throw new Error(
      'admin.database() unavailable. Ensure Firebase Admin SDK is initialized.',
    );
  }

  return _db;
}

/** Get the RTDB root URL with trailing slash (works in both real and emulator). */
export function getRTDBURL(): string {
  const dbUrl = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
  if (dbUrl) {
    const [host, port] = dbUrl.split(':');
    return `http://${host}:${port}/`;
  }

  const internal = admin as unknown as {
    apps: admin.app.App[];
    initializeApp(options?: { databaseURL?: string }): admin.app.App;
    database(): ReturnType<typeof admin.database>;
  };
  const apps = internal.apps ?? [];
  if (apps.length > 0) {
    const options = (apps[0] as unknown as { options: { databaseURL?: string } })
      ?.options?.databaseURL;
    if (options) return `${options}/`;
  }

  return 'https://may-family-finance-default-rtdb.firebaseio.com/';
}

/** Check if running in emulator mode. */
export function isEmulator(): boolean {
  return !!process.env.FIREBASE_DATABASE_EMULATOR_HOST;
}
