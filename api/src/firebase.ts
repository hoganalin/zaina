import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { readFileSync } from 'node:fs';

if (getApps().length === 0) {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath) {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf-8')) as Record<
      string,
      unknown
    >;
    initializeApp({ credential: cert(serviceAccount as Parameters<typeof cert>[0]) });
  } else {
    initializeApp();
  }
}
