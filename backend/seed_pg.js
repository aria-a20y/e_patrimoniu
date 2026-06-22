'use strict';
/**
 * seed_pg.js — Populează baza de date PostgreSQL (Render) cu date demo.
 * Rulare: node backend/seed_pg.js
 *        (din rădăcina proiectului)
 */

const { Pool } = require('pg');
const fs   = require('fs');
const path = require('path');

const DATABASE_URL =
  process.env.DATABASE_URL ||
  'postgresql://e_patrimoniu_db_user:yBXarNlKJIDMYAGVjLUczOVQZAm9EgNY@dpg-d8qmubh194ac7393udk0-a.ohio-postgres.render.com/e_patrimoniu_db';

const pool = new Pool({
  connectionString: DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function run() {
  const client = await pool.connect();
  try {
    console.log('[seed] Conectat la PostgreSQL...');

    // 1. Asigura-te ca schema exista
    const schemaSQL = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    console.log('[seed] Rulare schema.sql...');
    await client.query(schemaSQL);
    console.log('[seed] Schema OK.');

    // 2. Populeaza cu date demo
    const seedSQL = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    console.log('[seed] Rulare seed.sql...');
    await client.query(seedSQL);
    console.log('[seed] Date demo inserate cu succes!');

    // 3. Verificare rapida
    const r = await client.query('SELECT COUNT(*) FROM properties');
    console.log('[seed] Proprietati in DB:', r.rows[0].count);
    const r2 = await client.query('SELECT COUNT(*) FROM users');
    console.log('[seed] Utilizatori in DB:', r2.rows[0].count);

    console.log('\n✓ Seeding complet! Baza de date are date demo.');
  } catch (err) {
    console.error('[seed] EROARE:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
