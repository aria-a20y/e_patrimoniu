'use strict';

const admin = require('firebase-admin');

/**
 * Initialize Firebase Admin SDK.
 *
 * On Render, set the environment variable:
 *   FIREBASE_SERVICE_ACCOUNT = <contents of serviceAccountKey.json, single-line JSON>
 *
 * Locally, either:
 *   a) Set FIREBASE_SERVICE_ACCOUNT the same way, OR
 *   b) Place serviceAccountKey.json in this folder and set
 *      GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
 *
 * NEVER commit serviceAccountKey.json to git (it is in .gitignore).
 */

if (admin.apps.length === 0) {
  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Render / CI — JSON stored as environment variable
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      credential = admin.credential.cert(serviceAccount);
    } catch (err) {
      console.error('FIREBASE_SERVICE_ACCOUNT is not valid JSON:', err.message);
      process.exit(1);
    }
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    // Local development with a key file path
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
    storageBucket: 'e-patrimoniu.firebasestorage.app',
  });

  console.log('Firebase Admin SDK initialized (project: e-patrimoniu)');
}

const db   = admin.firestore();
const auth = admin.auth();

module.exports = { db, auth };
