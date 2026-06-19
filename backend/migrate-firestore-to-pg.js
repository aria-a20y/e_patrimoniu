/**
 * migrate-firestore-to-pg.js
 * ---------------------------------------------------------
 * Script de migrare: Firestore -> PostgreSQL
 *
 * Ruleaza LOCAL (nu pe Render) cu:
 *   node migrate-firestore-to-pg.js
 *
 * Necesita variabile de mediu (in .env sau shell):
 *   DATABASE_URL=postgresql://user:pass@host/db
 *   FIREBASE_SERVICE_ACCOUNT=<JSON complet>
 *
 * Ordinea migrarii respecta dependentele FK:
 *   1. users -> 2. properties -> 3. transactions
 *   -> 4. contracts -> 5. auctions -> 6. documents
 * ---------------------------------------------------------
 */

'use strict';

require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const admin = require('firebase-admin');
const { Pool } = require('pg');

// Firebase init
let serviceAccount;
try {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT nu este setata.');
  serviceAccount = JSON.parse(raw);
} catch (e) {
  console.error('[MIGRATE] Eroare FIREBASE_SERVICE_ACCOUNT:', e.message);
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// PostgreSQL init
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

// Helpers
function parseDate(v) {
  if (!v) return null;
  if (v && typeof v.toDate === 'function') return v.toDate();
  if (v instanceof Date) return v;
  const d = new Date(v);
  return isNaN(d) ? null : d;
}
function safeNum(v, fallback = 0) { const n = Number(v); return isNaN(n) ? fallback : n; }
function safeStr(v, fallback = '') { return v != null ? String(v).trim() : fallback; }
async function getAll(collection) {
  const snap = await db.collection(collection).get();
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

// --- Migrators ---

async function migrateUsers() {
  const docs = await getAll('users');
  console.log('[users] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  for (const u of docs) {
    try {
      await pool.query(
        'INSERT INTO users (uid,"firstName","lastName",email,phone,role,status,departament,photo_url,created_at) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ' +
        'ON CONFLICT (uid) DO UPDATE SET "firstName"=EXCLUDED."firstName","lastName"=EXCLUDED."lastName",' +
        'email=EXCLUDED.email,phone=EXCLUDED.phone,role=EXCLUDED.role,status=EXCLUDED.status,' +
        'departament=EXCLUDED.departament,photo_url=EXCLUDED.photo_url',
        [
          u.id, safeStr(u.firstName), safeStr(u.lastName),
          safeStr(u.email).toLowerCase(), safeStr(u.phone),
          ['administrator','functionar','extern'].includes(u.role) ? u.role : 'extern',
          ['activ','inactiv','suspendat'].includes(u.status) ? u.status : 'activ',
          u.departament ?? null, u.photoUrl ?? null,
          parseDate(u.createdAt) ?? new Date(),
        ]
      );
      ok++;
    } catch (e) { console.warn('  [users] Skip ' + u.id + ': ' + e.message); skip++; }
  }
  console.log('[users] ok=' + ok + ' skip=' + skip);
}

async function migrateProperties() {
  const docs = await getAll('properties');
  console.log('[properties] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  for (const p of docs) {
    try {
      await pool.query(
        'INSERT INTO properties (id,denumire,tip,adresa,localitate,domeniu_juridic,' +
        'numar_cadastral,numar_carte_f,suprafata,valoare_inventar,destinatie,status,' +
        'descriere,image_url,created_at,updated_at,created_by) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) ' +
        'ON CONFLICT (id) DO UPDATE SET denumire=EXCLUDED.denumire,tip=EXCLUDED.tip,' +
        'adresa=EXCLUDED.adresa,localitate=EXCLUDED.localitate,' +
        'suprafata=EXCLUDED.suprafata,valoare_inventar=EXCLUDED.valoare_inventar,' +
        'status=EXCLUDED.status,descriere=EXCLUDED.descriere,updated_at=EXCLUDED.updated_at',
        [
          p.id,
          safeStr(p.denumire, 'Fara denumire'),
          ['teren','cladire','spatiu','constructie'].includes(p.tip) ? p.tip : 'teren',
          safeStr(p.adresa), safeStr(p.localitate),
          ['public','privat'].includes(p.domeniuJuridic) ? p.domeniuJuridic : 'public',
          safeStr(p.numarCadastral), safeStr(p.numarCarteF),
          safeNum(p.suprafata, 1), safeNum(p.valoareInventar, 0),
          safeStr(p.destinatie),
          ['activ','inactiv','scosEvidenta','inLitigiu'].includes(p.status) ? p.status : 'activ',
          p.descriere ?? null, p.imageUrl ?? null,
          parseDate(p.createdAt) ?? new Date(),
          parseDate(p.updatedAt) ?? new Date(),
          p.createdBy ?? null,
        ]
      );
      ok++;
    } catch (e) { console.warn('  [properties] Skip ' + p.id + ': ' + e.message); skip++; }
  }
  console.log('[properties] ok=' + ok + ' skip=' + skip);
}

async function migrateTransactions() {
  const docs = await getAll('transactions');
  console.log('[transactions] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  const VALID = ['vanzare','cumparare','inchiriere','concesionare','dareAdministrare',
    'dareFolosintaGratuita','comodat','schimbImobiliar','transfer','preluarePatrimoniu',
    'scoatereEvidenta','modificareValoare'];
  for (const t of docs) {
    try {
      await pool.query(
        'INSERT INTO transactions (id,property_id,property_denumire,tip,descriere,' +
        'numar_hcl,data_tranzactie,status,note,created_at,created_by) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) ' +
        'ON CONFLICT (id) DO UPDATE SET tip=EXCLUDED.tip,status=EXCLUDED.status,' +
        'numar_hcl=EXCLUDED.numar_hcl,data_tranzactie=EXCLUDED.data_tranzactie',
        [
          t.id, t.propertyId, safeStr(t.propertyDenumire),
          VALID.includes(t.tip) ? t.tip : 'transfer',
          safeStr(t.descriere), safeStr(t.numarHcl),
          parseDate(t.dataTransactie) ?? new Date(),
          ['initiata','aprobata','inDerulare','finalizata','anulata'].includes(t.status) ? t.status : 'initiata',
          t.note ?? null, parseDate(t.createdAt) ?? new Date(), t.createdBy ?? null,
        ]
      );
      ok++;
    } catch (e) { console.warn('  [transactions] Skip ' + t.id + ': ' + e.message); skip++; }
  }
  console.log('[transactions] ok=' + ok + ' skip=' + skip);
}

async function migrateContracts() {
  const docs = await getAll('contracts');
  console.log('[contracts] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  for (const c of docs) {
    try {
      const start = parseDate(c.dataInceput) ?? new Date();
      let end = parseDate(c.dataFinal) ?? new Date();
      if (end <= start) end = new Date(start.getTime() + 86400000);
      await pool.query(
        'INSERT INTO contracts (id,property_id,property_denumire,transaction_id,' +
        'numar_contract,parte_contractanta,data_inceput,data_final,valoare,' +
        'valuta_moneda,status,document_url,note,created_at,created_by) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) ' +
        'ON CONFLICT (id) DO UPDATE SET status=EXCLUDED.status,valoare=EXCLUDED.valoare,' +
        'data_final=EXCLUDED.data_final,note=EXCLUDED.note',
        [
          c.id, c.propertyId, safeStr(c.propertyDenumire), c.transactionId ?? null,
          safeStr(c.numarContract, 'N/A'), safeStr(c.parteContractanta, 'N/A'),
          start, end, safeNum(c.valoare, 0), safeStr(c.valutaMoneda, 'RON'),
          ['activ','prelungit','reziliat','expirat','finalizat','anulat'].includes(c.status) ? c.status : 'activ',
          c.documentUrl ?? null, c.note ?? null,
          parseDate(c.createdAt) ?? new Date(), c.createdBy ?? null,
        ]
      );
      ok++;
    } catch (e) { console.warn('  [contracts] Skip ' + c.id + ': ' + e.message); skip++; }
  }
  console.log('[contracts] ok=' + ok + ' skip=' + skip);
}

async function migrateAuctions() {
  const docs = await getAll('auctions');
  console.log('[auctions] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  for (const a of docs) {
    try {
      const start = parseDate(a.dataInceput) ?? new Date();
      let end = parseDate(a.dataFinal) ?? new Date();
      if (end <= start) end = new Date(start.getTime() + 86400000);
      await pool.query(
        'INSERT INTO auctions (id,property_id,property_denumire,titlu,tip_atribuire,' +
        'pret_pornire,pas_licitare,garantie_participare,data_inceput,data_final,' +
        'status,castigator_id,castigator_nume,oferta_castigatoare,' +
        'transaction_id,contract_id,descriere,created_at,created_by) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19) ' +
        'ON CONFLICT (id) DO UPDATE SET status=EXCLUDED.status,' +
        'castigator_id=EXCLUDED.castigator_id,castigator_nume=EXCLUDED.castigator_nume,' +
        'oferta_castigatoare=EXCLUDED.oferta_castigatoare',
        [
          a.id, a.propertyId, safeStr(a.propertyDenumire),
          safeStr(a.titlu, 'Licitatie'),
          ['vanzare','inchiriere','concesionare'].includes(a.tipAtribuire) ? a.tipAtribuire : 'inchiriere',
          safeNum(a.pretPornire, 1), safeNum(a.pasLicitare, 1), safeNum(a.garantieParticipare, 0),
          start, end,
          ['draft','publicata','activa','inchisa','atribuita','anulata','contestata'].includes(a.status) ? a.status : 'draft',
          a.castigatorId ?? null, a.castigatorNume ?? null,
          a.ofertaCastigatoare != null ? safeNum(a.ofertaCastigatoare) : null,
          a.transactionId ?? null, a.contractId ?? null, a.descriere ?? null,
          parseDate(a.createdAt) ?? new Date(), a.createdBy ?? null,
        ]
      );
      ok++;
    } catch (e) { console.warn('  [auctions] Skip ' + a.id + ': ' + e.message); skip++; }
  }
  console.log('[auctions] ok=' + ok + ' skip=' + skip);
}

async function migrateDocuments() {
  const docs = await getAll('documents');
  console.log('[documents] ' + docs.length + ' documente');
  let ok = 0, skip = 0;
  const VALID = ['hcl','extrasCF','planCadastral','raportEvaluare',
    'contract','procesVerbal','actAditional','documentPlata','altele'];
  for (const d of docs) {
    try {
      await pool.query(
        'INSERT INTO documents (id,denumire,tip,status,file_url,file_type,file_size,' +
        'property_id,transaction_id,contract_id,auction_id,' +
        'numar_document,data_document,emitent,note,uploaded_at,uploaded_by) ' +
        'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) ' +
        'ON CONFLICT (id) DO UPDATE SET denumire=EXCLUDED.denumire,tip=EXCLUDED.tip,' +
        'status=EXCLUDED.status,file_url=EXCLUDED.file_url,note=EXCLUDED.note',
        [
          d.id, safeStr(d.denumire, 'Document'),
          VALID.includes(d.tip) ? d.tip : 'altele',
          ['neverificat','inVerificare','verificat','respins'].includes(d.status) ? d.status : 'neverificat',
          safeStr(d.fileUrl), safeStr(d.fileType, 'pdf'), safeNum(d.fileSize, 0),
          d.propertyId ?? null, d.transactionId ?? null,
          d.contractId ?? null, d.auctionId ?? null,
          d.numarDocument ?? null, parseDate(d.dataDocument) ?? null,
          d.emitent ?? null, d.note ?? null,
          parseDate(d.uploadedAt ?? d.createdAt) ?? new Date(),
          d.uploadedBy ?? d.createdBy ?? null,
        ]
      );
      ok++;
    } catch (e) { console.warn('  [documents] Skip ' + d.id + ': ' + e.message); skip++; }
  }
  console.log('[documents] ok=' + ok + ' skip=' + skip);
}

async function main() {
  console.log('=== e-Patrimoniu: Migrare Firestore -> PostgreSQL ===');
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    console.log('Conexiune PostgreSQL OK');
  } catch (e) {
    console.error('Conexiune PostgreSQL ESUAT:', e.message);
    process.exit(1);
  } finally { client.release(); }

  await migrateUsers();
  await migrateProperties();
  await migrateTransactions();
  await migrateContracts();
  await migrateAuctions();
  await migrateDocuments();

  console.log('\n=== Migrare completa! ===');
  await pool.end();
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
