'use strict';

const admin = require('firebase-admin');

/**
 * Initialize Firebase Admin SDK — AUTH ONLY.
 * Firestore nu mai este folosit; baza de date principală este PostgreSQL.
 *
 * Pe Render, setează variabila de mediu:
 *   FIREBASE_SERVICE_ACCOUNT = <conținutul serviceAccountKey.json, JSON pe o linie>
 *
 * Local:
 *   a) Setează FIREBASE_SERVICE_ACCOUNT, SAU
 *   b) Setează GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
 *
 * NICIODATĂ nu comite serviceAccountKey.json în git (este în .gitignore).
 */

if (admin.apps.length === 0) {
  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      credential = admin.credential.cert(serviceAccount);
    } catch (err) {
      console.error('FIREBASE_SERVICE_ACCOUNT is not valid JSON:', err.message);
      process.exit(1);
    }
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    credential = admin.credential.applicationDefault();
  } else {
    console.error(
      'Firebase Admin SDK: no credentials found.\n' +
      'Set FIREBASE_SERVICE_ACCOUNT env var (Render) or ' +
      'GOOGLE_APPLICATION_CREDENTIALS (local).'
    );
    process.exit(1);
  }

  admin.initializeApp({
    credential,
    projectId: 'e-patrimoniu',
  });

  console.log('Firebase Admin SDK initialized (auth only, project: e-patrimoniu)');
}

const auth = admin.auth();

module.exports = { auth };
