/** Mây Family Finance — Backend Common: RTDB Client
 *
 * Provides RTDB read/write operations that work in both the real SDK
 * and the Firebase Functions emulator stub (which does not expose admin.database()).
 */

import * as admin from 'firebase-admin';

// Type-safe accessors for Firebase internals (emulator compatibility).

/** Internal RTDB instance stored globally during emulator bootstrap. */
const RTDB_GLOBAL_KEY = '__may_rtdb_instance' as const;

interface AdminInternal {
  apps: admin.app.App[];
  initializeApp(options?: { databaseURL?: string }, name?: string): admin.app.App;
  database(): admin.database.Database;
}

function getAdminInternal(): AdminInternal {
  return admin as unknown as AdminInternal;
}

/** Access the emulator's RTDB instance stored in the global scope. */
function getGlobalRtdbInstance(): admin.database.Database | null {
  const g = global as Record<string, unknown>;
  const val = g[RTDB_GLOBAL_KEY];
  return (val as admin.database.Database | undefined) ?? null;
}

let _db: ReturnType<typeof admin.database> | null = null;

/** Get the Admin SDK database reference. Initializes if needed. */
export function getDatabase(): ReturnType<typeof admin.database> {
  if (_db) return _db;

  const internal = getAdminInternal();
  const emulatorRtdb = getGlobalRtdbInstance();
  if (emulatorRtdb) {
    _db = emulatorRtdb;
    return _db;
  }

  if (!internal.apps.length) {
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
      'admin.database() unavailable. Ensure Firebase Admin SDK is initialized with a databaseURL.',
    );
  }

  return _db;
}

/** Get the RTDB root URL (works in both real and emulator). */
export function getRTDBURL(): string {
  const dbUrl = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
  if (dbUrl) {
    const [host, port] = dbUrl.split(':');
    return `http://${host}:${port}`;
  }

  // Production: read from admin app config
  const internal = getAdminInternal();
  const apps = internal.apps ?? [];
  if (apps.length > 0) {
    const options = (apps[0] as unknown as { options?: { databaseURL?: string } }).options;
    if (options?.databaseURL) return options.databaseURL;
  }

  // Default production URL — will be overridden by env at runtime
  return 'https://may-family-finance-default-rtdb.firebaseio.com';
}
