// Mint a Firebase ID token for a seed author so we can curl auth-gated
// endpoints from the command line. Demo only; never use against real users.

import '../src/firebase.js';
import { getAuth } from 'firebase-admin/auth';

const FIREBASE_WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;
const SEED_UID = process.argv[2] ?? 'seed-author-hana';

if (!FIREBASE_WEB_API_KEY) {
  console.error('Set FIREBASE_WEB_API_KEY (the public Web API key from google-services.json).');
  process.exit(1);
}

const customToken = await getAuth().createCustomToken(SEED_UID);

const res = await fetch(
  `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_WEB_API_KEY}`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: customToken, returnSecureToken: true }),
  },
);
const json = (await res.json()) as { idToken?: string; error?: { message: string } };
if (!json.idToken) {
  console.error('Exchange failed:', json.error ?? json);
  process.exit(1);
}
console.log(json.idToken);
