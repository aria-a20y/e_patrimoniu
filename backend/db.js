'use strict';

const { Pool } = require('pg');
const fs   = require('fs');
const path = require('path');

/**
 * PostgreSQL connection pool.
 * Pe Render, setează variabila de mediu DATABASE_URL (furnizată automat
 * dacă adaugi un PostgreSQL addon la serviciul tău).
 */
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Render PostgreSQL necesită SSL — activăm ori de câte ori avem DATABASE_URL extern
  ssl: process.env.DATABASE_URL
    ? { rejectUnauthorized: false }
    : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('PostgreSQL pool error:', err.message);
});

/**
 * Rulează schema.sql la pornirea serverului.
 * Toate comenzile folosesc IF NOT EXISTS — sigur de apelat de mai multe ori.
 */
async function initDb() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await pool.query(schema);
    console.log('[DB] Schema inițializată cu succes.');
  } catch (err) {
    console.error('[DB] Eroare la inițializarea schemei:', err.message || err.code || JSON.stringify(err));
    // Nu oprim serverul — poate schema există deja parțial
  }
}

module.exports = { pool, initDb };
