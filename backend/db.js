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
async function migrateSchema() {
  // Adaugă coloanele noi în tabelele existente dacă lipsesc (migrare sigură).
  const migrations = [
    // documents: coloane adăugate după crearea inițială a tabelului
    `ALTER TABLE documents ADD COLUMN IF NOT EXISTS numar_document TEXT`,
    `ALTER TABLE documents ADD COLUMN IF NOT EXISTS data_document  DATE`,
    `ALTER TABLE documents ADD COLUMN IF NOT EXISTS emitent        TEXT`,
  ];
  for (const sql of migrations) {
    try {
      await pool.query(sql);
    } catch (err) {
      console.error('[DB] Eroare migrare:', err.message);
    }
  }
  console.log('[DB] Migrare schema finalizata.');
}

async function initDb() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await pool.query(schema);
    console.log('[DB] Schema initializata cu succes.');
    await migrateSchema();
    await seedDb();
    await seedExtra();
    await seedPropertyDocuments();
    await seedClosedAuctionBids();
    await seedAdditionalAuditLogs();
  } catch (err) {
    console.error('[DB] Eroare la initializarea schemei:', err.message || err.code || JSON.stringify(err));
  }
}

/**
 * Inserează date demo dacă tabelele sunt goale.
 * Rulează automat după initDb() — sigur de apelat de mai multe ori (ON CONFLICT DO NOTHING).
 */
async function seedDb() {
  try {
    const { rows } = await pool.query('SELECT COUNT(*) AS cnt FROM properties');
    if (parseInt(rows[0].cnt, 10) > 0) {
      console.log('[DB] Date demo deja existente, seed omis.');
      return;
    }

    console.log('[DB] Baza de date goala — inserez date demo...');

    // ── 1. USERS (7 intrari) ──────────────────────────────────────────────────
    await pool.query(`
      INSERT INTO users (uid, "firstName", "lastName", email, phone, role, status, departament) VALUES
      ('user_admin_001', 'Alexandru', 'Ionescu',    'alex.ionescu@primarie.ro',     '0721000001', 'administrator', 'activ',    'Directia Patrimoniu'),
      ('user_admin_002', 'Cristina',  'Moldovan',   'cristina.moldovan@primarie.ro','0721000008', 'administrator', 'activ',    'Directia Juridica'),
      ('user_func_001',  'Maria',     'Popescu',    'maria.popescu@primarie.ro',    '0721000002', 'functionar',    'activ',    'Serviciul Evidenta'),
      ('user_func_002',  'Ion',       'Dumitrescu', 'ion.dumitrescu@primarie.ro',   '0721000003', 'functionar',    'activ',    'Compartiment Juridic'),
      ('user_func_003',  'Elena',     'Constantin', 'elena.constantin@primarie.ro', '0721000004', 'functionar',    'activ',    'Directia Patrimoniu'),
      ('user_ext_001',   'George',    'Marinescu',  'george.marinescu@email.ro',    '0721000005', 'extern',        'activ',    NULL),
      ('user_ext_002',   'Ana',       'Gheorghe',   'ana.gheorghe@email.ro',        '0721000006', 'extern',        'activ',    NULL),
      ('user_ext_003',   'Radu',      'Popa',       'radu.popa@firma.ro',           '0721000007', 'extern',        'inactiv',  NULL)
      ON CONFLICT (uid) DO NOTHING
    `);

    // ── 2. PROPERTIES (7 intrari) ─────────────────────────────────────────────
    await pool.query(`
      INSERT INTO properties (id, denumire, tip, adresa, localitate, domeniu_juridic, numar_cadastral, numar_carte_f, suprafata, valoare_inventar, destinatie, status, descriere, created_by) VALUES
      ('a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',            'teren',      'Str. Florilor nr. 12',      'Iași', 'public',  '123456','CF-456789',  1250.00,   85000.00, 'Spatiu verde public',            'activ',      'Teren in domeniu public, str. Florilor','user_admin_001'),
      ('a0000002-0002-0002-0002-000000000002','Cladire Primarie Sector 2',             'cladire',    'B-dul Unirii nr. 5',        'Iași', 'public',  '234567','CF-567890',  3200.00, 1500000.00, 'Sediu administrativ primarie',   'activ',      'Cladire P+3, sediu Primariei Sector 2','user_admin_001'),
      ('a0000003-0003-0003-0003-000000000003','Spatiu Comercial Piata Centrala',       'spatiu',     'Piata Centrala nr. 1',      'Iași', 'privat',  '345678','CF-678901',   450.00,  320000.00, 'Spatiu comercial zona centrala', 'activ',      'Spatiu comercial parter, zona centrala','user_func_001'),
      ('a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',            'teren',      'Str. Industriei nr. 44',    'Iași', 'privat',  '456789','CF-789012',  8500.00,  420000.00, 'Teren activitati industriale',   'activ',      'Teren intravilan destinatie industriala','user_func_002'),
      ('a0000005-0005-0005-0005-000000000005','Constructie Dispensar Medical Rural',   'constructie','Str. Sanatatii nr. 3',      'Iași', 'public',  '567890','CF-890123',   680.00,  250000.00, 'Dispensar medical comunal',      'activ',      'Cladire P, dispensar medical UAT','user_func_001'),
      ('a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',               'teren',      'Str. Tineretului nr. 10',   'Iași', 'public',  '678901','CF-901234',  5200.00,  180000.00, 'Parc public recreere',           'activ',      'Teren amenajat ca parc de recreere','user_admin_001'),
      ('a0000007-0007-0007-0007-000000000007','Spatiu Birouri Centru Civic',           'spatiu',     'Calea Victoriei nr. 22',    'Iași', 'privat',  '789012','CF-012345',   320.00,  210000.00, 'Birouri administratie locala',   'inactiv',    'Spatiu birouri, necesita renovare','user_admin_002'),
      ('a0000008-0008-0008-0008-000000000008','Teren Extravilan Zona Agricola',        'teren',      'Tarla 5, Parcela 12',       'Iași', 'privat',  '890123','CF-123456', 12000.00,   95000.00, 'Teren agricol in litigiu',       'inLitigiu',  'Litigiu cu proprietar vecin privind limita de proprietate','user_func_002')
      ON CONFLICT (id) DO NOTHING
    `);

    // ── 3. TRANSACTIONS (7 intrari) ───────────────────────────────────────────
    await pool.query(`
      INSERT INTO transactions (id, property_id, property_denumire, tip, descriere, numar_hcl, data_tranzactie, status, created_by) VALUES
      ('b0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spatiu Comercial Piata Centrala',     'inchiriere',           'Inchiriere spatiu comercial SC Alfa SRL',                  'HCL-2024-045','2024-03-15','finalizata', 'user_admin_001'),
      ('b0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',          'concesionare',         'Concesionare teren industrial 25 ani SC Beta SA',          'HCL-2024-067','2024-04-20','finalizata', 'user_func_002'),
      ('b0000003-0003-0003-0003-000000000003','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',          'dareAdministrare',     'Dare in administrare Directiei Parcuri si Spatii Verzi',   'HCL-2024-089','2024-05-10','aprobata',  'user_admin_001'),
      ('b0000004-0004-0004-0004-000000000004','a0000005-0005-0005-0005-000000000005','Constructie Dispensar Medical Rural', 'dareFolosintaGratuita','Dare in folosinta gratuita Ministerului Sanatatii',        'HCL-2024-112','2024-06-01','inDerulare','user_func_001'),
      ('b0000005-0005-0005-0005-000000000005','a0000002-0002-0002-0002-000000000002','Cladire Primarie Sector 2',           'modificareValoare',    'Reevaluare imobil conform raport evaluator autorizat',     'HCL-2024-130','2024-07-15','finalizata', 'user_func_003'),
      ('b0000006-0006-0006-0006-000000000006','a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',             'dareAdministrare',     'Dare in administrare Directiei de Mediu Iasi',             'HCL-2024-155','2024-08-20','initiata',  'user_admin_001'),
      ('b0000007-0007-0007-0007-000000000007','a0000007-0007-0007-0007-000000000007','Spatiu Birouri Centru Civic',         'inchiriere',           'Inchiriere birouri SC Construct Plus SRL pe 2 ani',        'HCL-2024-178','2024-09-10','aprobata',  'user_admin_002'),
      ('b0000008-0008-0008-0008-000000000008','a0000008-0008-0008-0008-000000000008','Teren Extravilan Zona Agricola',      'preluarePatrimoniu',   'Preluare teren in patrimoniul UAT prin hotarare judec.',   'HCL-2024-201','2024-10-05','initiata',  'user_func_002')
      ON CONFLICT (id) DO NOTHING
    `);

    // ── 4. CONTRACTS (7 intrari) ──────────────────────────────────────────────
    await pool.query(`
      INSERT INTO contracts (id, property_id, property_denumire, transaction_id, numar_contract, parte_contractanta, data_inceput, data_final, valoare, valuta_moneda, status, note, created_by) VALUES
      ('c0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spatiu Comercial Piata Centrala',   'b0000001-0001-0001-0001-000000000001','CONTRACT-2024-001','SC Alfa SRL',                '2024-04-01','2027-03-31',   4800.00,'RON','activ',     'Chirie 400 RON/luna + TVA',                             'user_admin_001'),
      ('c0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',        'b0000002-0002-0002-0002-000000000002','CONTRACT-2024-002','SC Beta SA',                 '2024-05-01','2049-04-30', 125000.00,'RON','activ',     'Concesiune 25 ani, redeventa 5000 RON/an',              'user_func_002'),
      ('c0000003-0003-0003-0003-000000000003','a0000005-0005-0005-0005-000000000005','Constructie Dispensar Med. Rural',  'b0000004-0004-0004-0004-000000000004','CONTRACT-2024-003','Ministerul Sanatatii',       '2024-06-15','2026-06-14',      0.00,'RON','activ',     'Folosinta gratuita, beneficiarul plateste intretinerea','user_func_001'),
      ('c0000004-0004-0004-0004-000000000004','a0000003-0003-0003-0003-000000000003','Spatiu Comercial Piata Centrala',   NULL,                                  'CONTRACT-2022-015','SC Gamma SRL',              '2022-01-01','2024-12-31',  9600.00,'RON','expirat',    'Contract expirat, spatiu eliberat 31.12.2024',          'user_func_001'),
      ('c0000005-0005-0005-0005-000000000005','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',        'b0000003-0003-0003-0003-000000000003','CONTRACT-2024-004','Directia Parcuri Cluj',      '2024-06-01','2029-05-31',      0.00,'RON','activ',     'Administrare spatiu verde',                             'user_admin_001'),
      ('c0000006-0006-0006-0006-000000000006','a0000002-0002-0002-0002-000000000002','Cladire Primarie Sector 2',         NULL,                                  'CONTRACT-2023-008','Firma Constructii Delta SRL','2023-03-01','2023-12-31',  85000.00,'RON','finalizat',  'Lucrari renovare fatada si acoperis',                   'user_func_003'),
      ('c0000007-0007-0007-0007-000000000007','a0000007-0007-0007-0007-000000000007','Spatiu Birouri Centru Civic',       'b0000007-0007-0007-0007-000000000007','CONTRACT-2024-005','SC Construct Plus SRL',     '2024-10-01','2026-09-30',  14400.00,'RON','activ',     'Chirie 600 RON/luna, include utilitati',                'user_admin_002'),
      ('c0000008-0008-0008-0008-000000000008','a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',            'b0000006-0006-0006-0006-000000000006','CONTRACT-2024-006','Directia de Mediu Iasi',    '2024-09-01','2029-08-31',      0.00,'RON','activ',     'Administrare parc si intretinere zone verzi',           'user_admin_001')
      ON CONFLICT (id) DO NOTHING
    `);

    // ── 5. AUCTIONS (7 intrari) ───────────────────────────────────────────────
    await pool.query(`
      INSERT INTO auctions (id, property_id, property_denumire, titlu, tip_atribuire, pret_pornire, pas_licitare, garantie_participare, data_inceput, data_final, status, descriere, created_by) VALUES
      ('d0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spatiu Comercial Piata Centrala', 'Licitatie inchiriere spatiu comercial Piata Centrala 2025', 'inchiriere',    2500.00, 100.00,  500.00,'2025-01-10 09:00:00+02','2025-02-10 17:00:00+02','atribuita', 'Licitatie publica 3 ani',                             'user_admin_001'),
      ('d0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',     'Concesionare teren industrial zona nord Brasov',            'concesionare', 18000.00, 500.00, 3600.00,'2024-09-01 09:00:00+03','2024-10-01 17:00:00+03','atribuita', 'Concesionare 25 ani, drept de construire',            'user_func_002'),
      ('d0000003-0003-0003-0003-000000000003','a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',         'Licitatie activitati recreative Parc Tineretului',          'inchiriere',    1000.00,  50.00,  200.00,'2025-03-01 09:00:00+02','2025-04-01 17:00:00+02','publicata', 'Administrare activitati recreative si sportive',      'user_admin_001'),
      ('d0000004-0004-0004-0004-000000000004','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',     'Vanzare teren Str. Florilor nr. 12 Cluj-Napoca',            'vanzare',      75000.00,1000.00, 7500.00,'2025-05-01 09:00:00+03','2025-06-01 17:00:00+03','draft',     'Teren domeniu privat, licitatie publica conform HCL', 'user_admin_001'),
      ('d0000005-0005-0005-0005-000000000005','a0000002-0002-0002-0002-000000000002','Cladire Primarie Sector 2',      'Inchiriere sali conferinta Cladire Primarie Sector 2',      'inchiriere',     500.00,  25.00,  100.00,'2024-11-01 09:00:00+02','2024-12-01 17:00:00+02','inchisa',   'Sali conferinta evenimente corporative 1 an',         'user_func_003'),
      ('d0000006-0006-0006-0006-000000000006','a0000005-0005-0005-0005-000000000005','Constructie Dispensar Med. Rural','Concesionare teren aferent dispensar pentru extindere',    'concesionare',  3000.00, 100.00,  600.00,'2025-06-15 09:00:00+03','2025-07-15 17:00:00+03','draft',     'Concesionare 200 mp pentru cabinet stomatologic',    'user_func_001'),
      ('d0000007-0007-0007-0007-000000000007','a0000007-0007-0007-0007-000000000007','Spatiu Birouri Centru Civic',    'Inchiriere spatiu birouri Centru Civic Craiova 2025',       'inchiriere',     450.00,  25.00,   90.00,'2025-02-01 09:00:00+02','2025-03-01 17:00:00+02','activa',    'Birouri 320 mp, include parcare 2 locuri',             'user_admin_002')
      ON CONFLICT (id) DO NOTHING
    `);

    // UPDATE castigatori licitatii atribuite
    await pool.query(`
      UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / SC Alfa SRL',  oferta_castigatoare=2800.00  WHERE id='d0000001-0001-0001-0001-000000000001' AND castigator_id IS NULL;
      UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / SC Omega SRL', oferta_castigatoare=19000.00 WHERE id='d0000002-0002-0002-0002-000000000002' AND castigator_id IS NULL;
      UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / Events SRL',   oferta_castigatoare=550.00   WHERE id='d0000005-0005-0005-0005-000000000005' AND castigator_id IS NULL;
    `);

    // ── 6. BIDS (7 intrari) ───────────────────────────────────────────────────
    await pool.query(`
      INSERT INTO bids (id, auction_id, participant_id, participant_nume, valoare, data_ora, validata, respinsa) VALUES
      ('e0000001-0001-0001-0001-000000000001','d0000001-0001-0001-0001-000000000001','user_ext_001','George Marinescu / SC Alfa SRL',   2600.00,'2025-01-20 10:15:00+02',TRUE, FALSE),
      ('e0000002-0002-0002-0002-000000000002','d0000001-0001-0001-0001-000000000001','user_ext_002','Ana Gheorghe / SC Delta SRL',      2700.00,'2025-01-22 14:30:00+02',TRUE, FALSE),
      ('e0000003-0003-0003-0003-000000000003','d0000001-0001-0001-0001-000000000001','user_ext_001','George Marinescu / SC Alfa SRL',   2800.00,'2025-02-05 09:45:00+02',TRUE, FALSE),
      ('e0000004-0004-0004-0004-000000000004','d0000002-0002-0002-0002-000000000002','user_ext_002','Ana Gheorghe / SC Beta SA',       18500.00,'2024-09-15 11:00:00+03',TRUE, FALSE),
      ('e0000005-0005-0005-0005-000000000005','d0000002-0002-0002-0002-000000000002','user_ext_001','George Marinescu / SC Omega SRL', 19000.00,'2024-09-20 15:20:00+03',TRUE, FALSE),
      ('e0000006-0006-0006-0006-000000000006','d0000005-0005-0005-0005-000000000005','user_ext_002','Ana Gheorghe / Firma Sigma SRL',    525.00,'2024-11-15 10:00:00+02',TRUE, FALSE),
      ('e0000007-0007-0007-0007-000000000007','d0000005-0005-0005-0005-000000000005','user_ext_001','George Marinescu / Events SRL',     550.00,'2024-11-20 16:30:00+02',TRUE, FALSE),
      ('e0000008-0008-0008-0008-000000000008','d0000007-0007-0007-0007-000000000007','user_ext_003','Radu Popa / SC Office Space SRL',   480.00,'2025-02-10 11:00:00+02',TRUE, FALSE),
      ('e0000009-0009-0009-0009-000000000009','d0000007-0007-0007-0007-000000000007','user_ext_002','Ana Gheorghe / SC Birouri SRL',     500.00,'2025-02-15 14:00:00+02',FALSE,TRUE),
      ('e0000010-000a-000a-000a-00000000000a','d0000003-0003-0003-0003-000000000003','user_ext_001','George Marinescu / Sport Park SRL', 1050.00,'2025-03-15 09:00:00+02',FALSE,FALSE)
      ON CONFLICT (id) DO NOTHING
    `);

    // ── 7. AUCTION_PARTICIPANTS (7 intrari) ───────────────────────────────────
    await pool.query(`
      INSERT INTO auction_participants (id, auction_id, user_id) VALUES
      ('f0000001-0001-0001-0001-000000000001','d0000001-0001-0001-0001-000000000001','user_ext_001'),
      ('f0000002-0002-0002-0002-000000000002','d0000001-0001-0001-0001-000000000001','user_ext_002'),
      ('f0000003-0003-0003-0003-000000000003','d0000002-0002-0002-0002-000000000002','user_ext_001'),
      ('f0000004-0004-0004-0004-000000000004','d0000002-0002-0002-0002-000000000002','user_ext_002'),
      ('f0000005-0005-0005-0005-000000000005','d0000003-0003-0003-0003-000000000003','user_ext_001'),
      ('f0000006-0006-0006-0006-000000000006','d0000003-0003-0003-0003-000000000003','user_ext_002'),
      ('f0000007-0007-0007-0007-000000000007','d0000005-0005-0005-0005-000000000005','user_ext_001'),
      ('f0000008-0008-0008-0008-000000000008','d0000005-0005-0005-0005-000000000005','user_ext_002'),
      ('f0000009-0009-0009-0009-000000000009','d0000007-0007-0007-0007-000000000007','user_ext_003'),
      ('f000000a-000a-000a-000a-00000000000a','d0000007-0007-0007-0007-000000000007','user_ext_002')
      ON CONFLICT (auction_id, user_id) DO NOTHING
    `);

    // ── 8. DOCUMENTS (7 intrari) ──────────────────────────────────────────────
    await pool.query(`
      INSERT INTO documents (id, denumire, tip, status, file_url, file_type, file_size, property_id, transaction_id, contract_id, auction_id, numar_document, data_document, emitent, note, uploaded_by) VALUES
      ('da000001-0001-0001-0001-000000000001','Extras Carte Funciara Spatiu Piata Centrala',    'extrasCF',      'verificat','https://storage.epatrimoniu.ro/docs/cf_001.pdf',  'pdf', 245760,'a0000003-0003-0003-0003-000000000003',NULL,NULL,NULL,'CF-2024-001','2024-02-15','OCPI Timis',              'Extras CF actualizat, fara sarcini',              'user_func_001'),
      ('da000002-0002-0002-0002-000000000002','HCL nr. 45/2024 - Aprobare inchiriere spatiu',  'hcl',           'verificat','https://storage.epatrimoniu.ro/docs/hcl_045.pdf', 'pdf', 512000,'a0000003-0003-0003-0003-000000000003','b0000001-0001-0001-0001-000000000001',NULL,NULL,'HCL-45/2024','2024-03-10','Consiliul Local Timisoara','HCL aprobat 18 voturi pentru',                   'user_admin_001'),
      ('da000003-0003-0003-0003-000000000003','Contract inchiriere SC Alfa SRL 2024-2027',     'contract',      'verificat','https://storage.epatrimoniu.ro/docs/cont_001.pdf','pdf',1048576,'a0000003-0003-0003-0003-000000000003','b0000001-0001-0001-0001-000000000001','c0000001-0001-0001-0001-000000000001',NULL,'CONTRACT-2024-001','2024-04-01','Primaria Timisoara',      'Contract semnat de ambele parti',                'user_func_001'),
      ('da000004-0004-0004-0004-000000000004','Plan Cadastral Teren Industrial Brasov',        'planCadastral', 'verificat','https://storage.epatrimoniu.ro/docs/plan_001.pdf','pdf', 819200,'a0000004-0004-0004-0004-000000000004',NULL,NULL,NULL,'PC-2024-044','2024-03-20','OCPI Brasov',             'Plan cadastral vizat ANCPI, scara 1:500',         'user_func_002'),
      ('da000005-0005-0005-0005-000000000005','Raport Evaluare Cladire Primarie Sector 2',     'raportEvaluare','verificat','https://storage.epatrimoniu.ro/docs/eval_001.pdf','pdf',2097152,'a0000002-0002-0002-0002-000000000002','b0000005-0005-0005-0005-000000000005',NULL,NULL,'RE-2024-007','2024-07-01','Expert Evaluator ANEVAR',  'Valoare piata: 2.100.000 RON',                   'user_func_003'),
      ('da000006-0006-0006-0006-000000000006','Proces Verbal Predare-Primire Dispensar',       'procesVerbal',  'verificat','https://storage.epatrimoniu.ro/docs/pv_001.pdf',  'pdf', 153600,'a0000005-0005-0005-0005-000000000005','b0000004-0004-0004-0004-000000000004','c0000003-0003-0003-0003-000000000003',NULL,'PV-2024-012','2024-06-15','Comisie predare-primire',  'PV semnat UAT si Ministerul Sanatatii',           'user_func_001'),
      ('da000007-0007-0007-0007-000000000007','HCL nr. 67/2024 - Concesionare teren ind.',    'hcl',           'verificat','https://storage.epatrimoniu.ro/docs/hcl_067.pdf', 'pdf', 491520,'a0000004-0004-0004-0004-000000000004','b0000002-0002-0002-0002-000000000002',NULL,'d0000002-0002-0002-0002-000000000002','HCL-67/2024','2024-04-15','Consiliul Local Brasov',  'HCL aprobat, publicat pe site primarie',          'user_admin_001'),
      ('da000008-0008-0008-0008-000000000008','Act Aditional Contract Alfa SRL nr. 1/2025',   'actAditional',  'neverificat','https://storage.epatrimoniu.ro/docs/adit_001.pdf','pdf', 204800,'a0000003-0003-0003-0003-000000000003',NULL,'c0000001-0001-0001-0001-000000000001',NULL,'ACT-ADIT-2025-001','2025-01-15','Primaria Timisoara',    'Modificare valoare chirie la 450 RON/luna',      'user_func_001')
      ON CONFLICT (id) DO NOTHING
    `);

    // ── 9. AUDIT_LOG (10 intrari) ─────────────────────────────────────────────
    await pool.query(`
      INSERT INTO audit_log (id, user_id, user_name, actiune, entitate, entitate_id, detalii, ip_address) VALUES
      ('ab000001-0001-0001-0001-000000000001','user_admin_001','Alexandru Ionescu','CREATE','properties',  'a0000001-0001-0001-0001-000000000001','Adaugat bun imobil: Teren Str. Florilor nr. 12',              '192.168.1.100'),
      ('ab000002-0002-0002-0002-000000000002','user_func_001', 'Maria Popescu',   'CREATE','contracts',   'c0000001-0001-0001-0001-000000000001','Creat contract inchiriere SC Alfa SRL, valoare 4800 RON',      '192.168.1.101'),
      ('ab000003-0003-0003-0003-000000000003','user_admin_001','Alexandru Ionescu','CREATE','auctions',    'd0000001-0001-0001-0001-000000000001','Publicata licitatie spatiu comercial Piata Centrala 2025',    '192.168.1.100'),
      ('ab000004-0004-0004-0004-000000000004','user_ext_001',  'George Marinescu','CREATE','bids',        'e0000003-0003-0003-0003-000000000003','Depusa oferta 2800 RON la licitatia spatiu comercial',        '10.0.0.55'),
      ('ab000005-0005-0005-0005-000000000005','user_admin_001','Alexandru Ionescu','UPDATE','auctions',    'd0000001-0001-0001-0001-000000000001','Atribuit castigator: George Marinescu, oferta 2800 RON',      '192.168.1.100'),
      ('ab000006-0006-0006-0006-000000000006','user_func_002', 'Ion Dumitrescu',  'CREATE','transactions','b0000002-0002-0002-0002-000000000002','Initiata tranzactie concesionare teren industrial Brasov',    '192.168.1.102'),
      ('ab000007-0007-0007-0007-000000000007','user_func_003', 'Elena Constantin','UPDATE','properties',  'a0000002-0002-0002-0002-000000000002','Actualizata valoare inventar cladire: 1.500.000 RON',         '192.168.1.103'),
      ('ab000008-0008-0008-0008-000000000008','user_func_001', 'Maria Popescu',   'CREATE','documents',   'da000003-0003-0003-0003-000000000003','Incarcat document: Contract inchiriere SC Alfa SRL 2024-2027','192.168.1.101'),
      ('ab000009-0009-0009-0009-000000000009','user_admin_001','Alexandru Ionescu','VIEW',  'reports',     NULL,                                 'Generat raport situatie contracte active - iunie 2024',       '192.168.1.100'),
      ('ab000010-000a-000a-000a-00000000000a','user_ext_002',  'Ana Gheorghe',    'CREATE','bids',        'e0000006-0006-0006-0006-000000000006','Depusa oferta 525 RON la licitatia sali conferinta',          '10.0.0.66'),
      ('ab000011-000b-000b-000b-00000000000b','user_admin_002','Cristina Moldovan','CREATE','users',       'user_ext_003',                       'Cont extern creat pentru Radu Popa / SC Office Space SRL',    '192.168.1.104'),
      ('ab000012-000c-000c-000c-00000000000c','user_func_002', 'Ion Dumitrescu',  'CREATE','properties',  'a0000008-0008-0008-0008-000000000008','Inregistrat teren extravilan in litigiu, dosar nr. 1234/2024','192.168.1.102')
      ON CONFLICT (id) DO NOTHING
    `);

    console.log('[DB] Date demo inserate cu succes! (8 tabele populate, minim 7 randuri fiecare)');
  } catch (err) {
    console.error('[DB] Eroare la seeding:', err.message || err);
  }
}

/**
 * Inserează câte un document (extrasCF) pentru fiecare proprietate
 * care nu are niciun document asociat.
 * Idempotent — sigur de apelat de mai multe ori.
 */
async function seedPropertyDocuments() {
  try {
    // Migrare: toate bunurile -> Municipiul Iași
    await pool.query(`UPDATE properties SET localitate = 'Iași' WHERE localitate != 'Iași'`);

    // Inserează document implicit pentru fiecare bun fără documente
    const result = await pool.query(`
      INSERT INTO documents (denumire, tip, status, file_url, file_type, file_size, property_id)
      SELECT
        'Document cadastral - ' || p.denumire,
        'extrasCF',
        'neverificat',
        '',
        'pdf',
        0,
        p.id
      FROM properties p
      WHERE NOT EXISTS (
        SELECT 1 FROM documents d WHERE d.property_id = p.id
      )
    `);
    if (result.rowCount > 0) {
      console.log(`[DB] Documente inserate automat pentru ${result.rowCount} bunuri fara documente.`);
    }
  } catch (err) {
    console.error('[DB] Eroare la seedPropertyDocuments:', err.message || err);
  }
}

/**
 * Rulează seed_extra.sql la fiecare pornire a serverului.
 * Folosește ON CONFLICT DO NOTHING — sigur de apelat de mai multe ori.
 * Adaugă datele suplimentare (20 proprietăți, 24 tranzacții, 30 contracte, 44 licitații)
 * chiar dacă baza nu e goală.
 */
/**
 * Adaugă oferte (bids) pentru licitațiile cu status 'inchisa' sau 'atribuita'.
 * Fiecare licitație încheiată va avea minim 7 oferte, cu valori crescătoare.
 * Rulează la fiecare pornire — idempotent (ON CONFLICT DO NOTHING).
 */
async function seedClosedAuctionBids() {
  try {
    // Obține licitațiile încheiate (inchisa sau atribuita) care au sub 7 oferte
    const { rows: auctions } = await pool.query(`
      SELECT a.id, a.pret_pornire, a.pas_licitare,
             COUNT(b.id) AS bid_count
      FROM auctions a
      LEFT JOIN bids b ON b.auction_id = a.id
      WHERE a.status IN ('inchisa', 'atribuita')
      GROUP BY a.id, a.pret_pornire, a.pas_licitare
      HAVING COUNT(b.id) < 7
    `);

    if (auctions.length === 0) {
      console.log('[DB] Licitații încheiate: toate au deja minim 7 oferte.');
      return;
    }

    const participants = [
      { id: 'user_ext_001', nume: 'George Marinescu / SC Alfa SRL' },
      { id: 'user_ext_002', nume: 'Ana Gheorghe / SC Beta SRL' },
      { id: 'user_ext_003', nume: 'Radu Popa / SC Omega SRL' },
    ];

    for (const auction of auctions) {
      const existing = parseInt(auction.bid_count, 10);
      const needed   = 7 - existing;
      const pas      = parseFloat(auction.pas_licitare) || 50;
      let baseVal    = parseFloat(auction.pret_pornire) + (existing + 1) * pas;

      for (let i = 0; i < needed; i++) {
        const p = participants[i % participants.length];
        const val = (baseVal + i * pas).toFixed(2);
        const daysAgo = needed - i;
        await pool.query(`
          INSERT INTO bids (auction_id, participant_id, participant_nume, valoare, data_ora, validata, respinsa)
          VALUES ($1, $2, $3, $4, NOW() - ($5 || ' days')::INTERVAL, TRUE, FALSE)
          ON CONFLICT DO NOTHING
        `, [auction.id, p.id, p.nume, val, daysAgo]);
      }
    }
    console.log(`[DB] Oferte adăugate pentru ${auctions.length} licitații încheiate.`);
  } catch (err) {
    console.error('[DB] Eroare seedClosedAuctionBids:', err.message || err);
  }
}

/**
 * Adaugă 4 intrări noi în jurnal de audit la fiecare pornire (dacă nu există).
 * Idempotent — folosește ID-uri fixe cu ON CONFLICT DO NOTHING.
 */
async function seedAdditionalAuditLogs() {
  try {
    await pool.query(`
      INSERT INTO audit_log (id, user_id, user_name, actiune, entitate, entitate_id, detalii, ip_address) VALUES
      ('ac000001-0001-0001-0001-000000000001','user_admin_001','Alexandru Ionescu','UPDATE','contracts', 'c0000002-0002-0002-0002-000000000002','Actualizat contract concesionare teren industrial: prelungire 5 ani','192.168.1.100'),
      ('ac000002-0002-0002-0002-000000000002','user_func_001', 'Maria Popescu',   'CREATE','documents', 'da000008-0008-0008-0008-000000000008','Incarcat act aditional contract Alfa SRL, modificare valoare chirie','192.168.1.101'),
      ('ac000003-0003-0003-0003-000000000003','user_admin_002','Cristina Moldovan','UPDATE','users',    'user_ext_001','Actualizat status utilizator George Marinescu: extern -> activ verificat','192.168.1.104'),
      ('ac000004-0004-0004-0004-000000000004','user_func_002', 'Ion Dumitrescu',  'CREATE','auctions',  'd000000b-000b-000b-000b-00000000000b','Publicata licitatie concesionare teren tenis Complex Sibiu','192.168.1.102')
      ON CONFLICT (id) DO NOTHING
    `);
    console.log('[DB] Jurnale de audit suplimentare inserate (4 înregistrări).');
  } catch (err) {
    console.error('[DB] Eroare seedAdditionalAuditLogs:', err.message || err);
  }
}

async function seedExtra() {
  try {
    const seedExtraPath = path.join(__dirname, 'seed_extra.sql');
    if (!fs.existsSync(seedExtraPath)) {
      console.log('[DB] seed_extra.sql nu există, omis.');
      return;
    }
    const sql = fs.readFileSync(seedExtraPath, 'utf8');
    await pool.query(sql);
    console.log('[DB] seed_extra.sql rulat cu succes — date suplimentare inserate.');
  } catch (err) {
    console.error('[DB] Eroare la seed_extra:', err.message || err);
  }
}

module.exports = { pool, initDb };
