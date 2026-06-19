'use strict';

const { pool } = require('../db');

/**
 * writeAuditLog — inserează o înregistrare în tabela `audit_log`.
 * userId/userName vin exclusiv din token-ul verificat (nu din body) — previne spoofing.
 */
async function writeAuditLog({ userId, userName, actiune, entitate, entitateId = null, detalii }) {
  try {
    await pool.query(
      `INSERT INTO audit_log (user_id, user_name, actiune, entitate, entitate_id, detalii)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, userName, actiune, entitate, entitateId, detalii ?? null]
    );
  } catch (err) {
    // Eșecul audit log nu trebuie să blocheze operațiunea principală
    console.error('audit_log write failed:', err.message);
  }
}

module.exports = { writeAuditLog };
