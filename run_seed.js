// run_seed.js — rulează seed_extra.sql pe baza de date Render
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const DB_URL = 'postgresql://e_patrimoniu_db_lmkt_user:bK8YPUu07OEzSCxo7nq5dxspOH1Pd5dt@dpg-d8tfhkhkh4rs73c0b570-a.frankfurt-postgres.render.com/e_patrimoniu_db_lmkt';

async function run() {
  const client = new Client({
    connectionString: DB_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('✅ Conectat la baza de date Render');

    const sqlFile = path.join(__dirname, 'backend', 'seed_extra.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    // Split on semicolons but keep UPDATE statements together
    // Execute the entire SQL as one block
    await client.query(sql);
    console.log('✅ Seed-ul a fost rulat cu succes!');

    // Verificare numere
    const res = await client.query(`
      SELECT
        (SELECT COUNT(*) FROM properties) as properties,
        (SELECT COUNT(*) FROM transactions) as transactions,
        (SELECT COUNT(*) FROM contracts) as contracts,
        (SELECT COUNT(*) FROM auctions) as auctions
    `);
    console.log('📊 Înregistrări în baza de date:');
    console.table(res.rows[0]);

  } catch (err) {
    console.error('❌ Eroare:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
