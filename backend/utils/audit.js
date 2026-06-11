'use strict';

const { db } = require('../firebase');
const { FieldValue } = require('firebase-admin/firestore');

/**
 * writeAuditLog — scrie o înregistrare în colecția `audit_log`.
 * Subiectul (userId, userName) este derivat din token-ul verificat de middleware,
 * nu din parametrii apelantului — previne audit log spoofing (F-06).
 */
async function writeAuditLog({ userId, userName, actiune, entitate, entitateId = null, detalii }) {
  try {
    await db.collection('audit_log').add({
      userId,
      userName,
      actiune,
      entitate,
      entitateId,
      detalii,
      timestamp: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    // Audit failure should not break the main operation — log to console only.
    console.error('audit_log write failed:', err.message);
  }
}

module.exports = { writeAuditLog };
