/**
 * seed.js - Populează Firestore cu date demo pentru e-Patrimoniu
 * Rulare: node seed.js
 *
 * Creează:
 *  - 5 utilizatori (1 admin, 1 funcționar, 3 externi pentru licitație)
 *  - 8 bunuri imobiliare (2 x teren, 2 x clădire, 2 x spațiu, 2 x construcție)
 *  - 5 tranzacții
 *  - 6 documente
 *  - 2 contracte legate de bunuri
 *  - 1 licitație activă cu 3 oferte
 */

const https = require('https');

const PROJECT_ID = 'e-patrimoniu';
const API_KEY = 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE';
const FS_BASE = `firestore.googleapis.com`;
const FS_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const AUTH_HOST = `identitytoolkit.googleapis.com`;

// ─── HTTP helper ──────────────────────────────────────────────────────────────

function post(host, path, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = JSON.stringify(body);
    const opts = {
      hostname: host,
      path: `${path}?key=${API_KEY}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(bodyStr),
      },
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch { resolve(data); }
      });
    });
    req.on('error', reject);
    req.write(bodyStr);
    req.end();
  });
}

function patch(host, path, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = JSON.stringify(body);
    const opts = {
      hostname: host,
      path: `${path}?key=${API_KEY}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(bodyStr),
      },
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch { resolve(data); }
      });
    });
    req.on('error', reject);
    req.write(bodyStr);
    req.end();
  });
}

// ─── Firestore value serializer ──────────────────────────────────────────────

function fv(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'string') return { stringValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(fv) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) fields[k] = fv(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toDoc(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = fv(v);
  return { fields };
}

// ─── Firestore write ──────────────────────────────────────────────────────────

async function setDoc(collection, docId, data) {
  const path = `${FS_PATH}/${collection}/${docId}`;
  const result = await patch(FS_BASE, path, toDoc(data));
  if (result.error) {
    console.error(`  ✗ ${collection}/${docId}: ${result.error.message}`);
  } else {
    console.log(`  ✓ ${collection}/${docId}`);
  }
  return result;
}

// ─── Firebase Auth helpers ───────────────────────────────────────────────────

async function createAuthUser(email, password) {
  const result = await post(AUTH_HOST, '/v1/accounts:signUp', {
    email, password, returnSecureToken: true,
  });
  if (result.error) {
    if (result.error.message === 'EMAIL_EXISTS') {
      // sign in to get UID
      const signin = await post(AUTH_HOST, '/v1/accounts:signInWithPassword', {
        email, password, returnSecureToken: true,
      });
      if (!signin.error) {
        console.log(`  ↩ user exists: ${email} (${signin.localId})`);
        return signin.localId;
      }
      // user exists but different password — we can't get UID easily, generate placeholder
      console.log(`  ⚠ user ${email} exists with different password — using placeholder UID`);
      return `existing_${email.replace(/[@.]/g, '_')}`;
    }
    console.error(`  ✗ auth ${email}: ${result.error.message}`);
    return `failed_${email.replace(/[@.]/g, '_')}`;
  }
  console.log(`  ✓ auth created: ${email} (${result.localId})`);
  return result.localId;
}

// ─── Main seed ────────────────────────────────────────────────────────────────

async function seed() {
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║  e-Patrimoniu — Seed Firestore Demo Data  ║');
  console.log('╚══════════════════════════════════════════╝\n');

  const NOW = new Date();
  const d = (y, m, day) => new Date(y, m - 1, day);

  // ── 1. UTILIZATORI ────────────────────────────────────────────────────────
  console.log('▸ 1/6  Utilizatori...');

  const uidAdmin     = await createAuthUser('admin@epatrimoniu.ro',         'Admin1234!');
  const uidFunc      = await createAuthUser('functionar@epatrimoniu.ro',    'Functionar1234!');
  const uidExt1      = await createAuthUser('participant1@epatrimoniu.ro',  'Participant1234!');
  const uidExt2      = await createAuthUser('participant2@epatrimoniu.ro',  'Participant1234!');
  const uidExt3      = await createAuthUser('participant3@epatrimoniu.ro',  'Participant1234!');

  await setDoc('users', uidAdmin, {
    firstName: 'Ion', lastName: 'Popescu',
    email: 'admin@epatrimoniu.ro', phone: '0721000001',
    role: 'administrator', status: 'activ',
    departament: 'Compartiment Patrimoniu',
    createdAt: d(2024, 1, 10),
  });
  await setDoc('users', uidFunc, {
    firstName: 'Maria', lastName: 'Ionescu',
    email: 'functionar@epatrimoniu.ro', phone: '0721000002',
    role: 'functionar', status: 'activ',
    departament: 'Compartiment Urbanism',
    createdAt: d(2024, 2, 14),
  });
  await setDoc('users', uidExt1, {
    firstName: 'Andrei', lastName: 'Constantin',
    email: 'participant1@epatrimoniu.ro', phone: '0731100001',
    role: 'extern', status: 'activ',
    createdAt: d(2024, 3, 5),
  });
  await setDoc('users', uidExt2, {
    firstName: 'Elena', lastName: 'Dumitrescu',
    email: 'participant2@epatrimoniu.ro', phone: '0731100002',
    role: 'extern', status: 'activ',
    createdAt: d(2024, 3, 7),
  });
  await setDoc('users', uidExt3, {
    firstName: 'Mihai', lastName: 'Popa',
    email: 'participant3@epatrimoniu.ro', phone: '0731100003',
    role: 'extern', status: 'activ',
    createdAt: d(2024, 3, 9),
  });

  // ── 2. BUNURI IMOBILIARE ──────────────────────────────────────────────────
  console.log('\n▸ 2/6  Bunuri imobiliare...');

  // Terenuri
  await setDoc('properties', 'prop_teren_1', {
    denumire: 'Teren intravilan Str. Florilor nr. 12',
    tip: 'teren', adresa: 'Str. Florilor nr. 12',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'public',
    numarCadastral: '318452', numarCarteF: '248710',
    suprafata: 1500.0, valoareInventar: 450000.0,
    destinatie: 'Parc și spații verzi', status: 'activ',
    descriere: 'Teren intravilan destinat amenajării unui parc urban. Suprafață totală 1500 mp.',
    createdAt: d(2024, 1, 15), updatedAt: d(2024, 1, 15), createdBy: uidAdmin,
  });
  await setDoc('properties', 'prop_teren_2', {
    denumire: 'Teren extravilan sector agricol Vest',
    tip: 'teren', adresa: 'Sector agricol Vest, parcela 142',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'privat',
    numarCadastral: '124580', numarCarteF: '185930',
    suprafata: 8200.0, valoareInventar: 123000.0,
    destinatie: 'Teren agricol arabil', status: 'activ',
    descriere: 'Teren extravilan categoria arabil, parcela 142 din tarlaua 18.',
    createdAt: d(2024, 1, 20), updatedAt: d(2024, 1, 20), createdBy: uidAdmin,
  });

  // Clădiri
  await setDoc('properties', 'prop_cladire_1', {
    denumire: 'Clădire administrativă Piața Unirii nr. 1',
    tip: 'cladire', adresa: 'Piața Unirii nr. 1',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'public',
    numarCadastral: '205610', numarCarteF: '312450',
    suprafata: 2200.0, valoareInventar: 3500000.0,
    destinatie: 'Sediu administrativ — Primărie', status: 'activ',
    descriere: 'Imobil cu destinație administrativă, P+3 etaje, suprafață construită desfășurată 2200 mp.',
    createdAt: d(2023, 11, 5), updatedAt: d(2024, 2, 10), createdBy: uidAdmin,
  });
  await setDoc('properties', 'prop_cladire_2', {
    denumire: 'Casa de Cultură Str. Mihai Eminescu nr. 15',
    tip: 'cladire', adresa: 'Str. Mihai Eminescu nr. 15',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'public',
    numarCadastral: '187430', numarCarteF: '294870',
    suprafata: 850.0, valoareInventar: 1200000.0,
    destinatie: 'Cultură și activități comunitare', status: 'activ',
    descriere: 'Imobil P+1, destinat activităților culturale și evenimentelor comunitare.',
    createdAt: d(2023, 12, 1), updatedAt: d(2023, 12, 1), createdBy: uidAdmin,
  });

  // Spații
  await setDoc('properties', 'prop_spatiu_1', {
    denumire: 'Spațiu comercial parter Bloc A2 ap. 1',
    tip: 'spatiu', adresa: 'Str. Partizanilor nr. 8, Bloc A2, parter ap. 1',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'privat',
    numarCadastral: '334210', numarCarteF: '412870',
    suprafata: 65.0, valoareInventar: 95000.0,
    destinatie: 'Spațiu comercial', status: 'activ',
    descriere: 'Spațiu la parter cu vitrine stradale, ideal comercial sau servicii.',
    createdAt: d(2024, 3, 10), updatedAt: d(2024, 3, 10), createdBy: uidFunc,
  });
  await setDoc('properties', 'prop_spatiu_2', {
    denumire: 'Spațiu birou etaj 2 Primărie — Sala B201',
    tip: 'spatiu', adresa: 'Piața Unirii nr. 1, etaj 2',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'public',
    numarCadastral: '205610', numarCarteF: '312450',
    suprafata: 120.0, valoareInventar: 180000.0,
    destinatie: 'Birou instituțional', status: 'activ',
    descriere: 'Spațiu de birouri în clădirea Primăriei, etaj 2, 3 camere + hol.',
    createdAt: d(2024, 4, 1), updatedAt: d(2024, 4, 1), createdBy: uidAdmin,
  });

  // Construcții
  await setDoc('properties', 'prop_constructie_1', {
    denumire: 'Garaj comunal Str. Independenței nr. 8',
    tip: 'constructie', adresa: 'Str. Independenței nr. 8',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'privat',
    numarCadastral: '291540', numarCarteF: '358900',
    suprafata: 40.0, valoareInventar: 25000.0,
    destinatie: 'Garaj', status: 'activ',
    descriere: 'Construcție parter, structură metalică, destinată parcării auto.',
    createdAt: d(2024, 2, 20), updatedAt: d(2024, 2, 20), createdBy: uidFunc,
  });
  await setDoc('properties', 'prop_constructie_2', {
    denumire: 'Magazie depozit zona industrială Nord',
    tip: 'constructie', adresa: 'Zona Industrială Nord, parcela 7',
    localitate: 'Cluj-Napoca', domeniuJuridic: 'public',
    numarCadastral: '145680', numarCarteF: '210340',
    suprafata: 350.0, valoareInventar: 85000.0,
    destinatie: 'Depozitare materiale', status: 'activ',
    descriere: 'Hală de depozitare materiale edilitate, suprafață utilă 350 mp.',
    createdAt: d(2023, 10, 15), updatedAt: d(2023, 10, 15), createdBy: uidAdmin,
  });

  // ── 3. TRANZACȚII ─────────────────────────────────────────────────────────
  console.log('\n▸ 3/6  Tranzacții...');

  await setDoc('transactions', 'trx_1', {
    propertyId: 'prop_spatiu_1', propertyDenumire: 'Spațiu comercial parter Bloc A2 ap. 1',
    tip: 'inchiriere',
    descriere: 'Închiriere spațiu comercial către SC TechHub SRL pe perioadă determinată 2 ani.',
    numarHcl: 'HCL 45/2024', dataTransactie: d(2024, 4, 15),
    status: 'finalizata', documentIds: ['doc_1', 'doc_5'],
    note: 'Contract semnat, spațiu predat la 01.05.2024.',
    createdAt: d(2024, 4, 10), createdBy: uidAdmin,
  });
  await setDoc('transactions', 'trx_2', {
    propertyId: 'prop_cladire_1', propertyDenumire: 'Clădire administrativă Piața Unirii nr. 1',
    tip: 'dareAdministrare',
    descriere: 'Dare în administrare a clădirii administrative către Consiliul Local.',
    numarHcl: 'HCL 12/2024', dataTransactie: d(2024, 1, 25),
    status: 'inDerulare', documentIds: ['doc_2'],
    note: 'Administrare în curs, termen revizuire anuală.',
    createdAt: d(2024, 1, 20), createdBy: uidAdmin,
  });
  await setDoc('transactions', 'trx_3', {
    propertyId: 'prop_teren_1', propertyDenumire: 'Teren intravilan Str. Florilor nr. 12',
    tip: 'concesionare',
    descriere: 'Concesionare teren pentru amenajare loc de joacă — SC Urban Green SRL.',
    numarHcl: 'HCL 78/2023', dataTransactie: d(2023, 11, 10),
    status: 'aprobata', documentIds: ['doc_3', 'doc_6'],
    note: 'Aprobat, în așteptarea semnării contractului de concesiune.',
    createdAt: d(2023, 11, 5), createdBy: uidAdmin,
  });
  await setDoc('transactions', 'trx_4', {
    propertyId: 'prop_constructie_1', propertyDenumire: 'Garaj comunal Str. Independenței nr. 8',
    tip: 'vanzare',
    descriere: 'Vânzare garaj ca urmare a licitației publice nr. 2024-001.',
    numarHcl: 'HCL 92/2024', dataTransactie: d(2024, 5, 20),
    status: 'finalizata', documentIds: [],
    note: 'Tranzacție finalizată, titlu de proprietate emis.',
    createdAt: d(2024, 5, 15), createdBy: uidFunc,
  });
  await setDoc('transactions', 'trx_5', {
    propertyId: 'prop_constructie_2', propertyDenumire: 'Magazie depozit zona industrială Nord',
    tip: 'transfer',
    descriere: 'Transfer magazie din domeniul public în administrarea Direcției Tehnice.',
    numarHcl: 'HCL 8/2024', dataTransactie: d(2024, 1, 15),
    status: 'initiata', documentIds: [],
    note: 'Dosar în pregătire, așteptare avize.',
    createdAt: d(2024, 1, 12), createdBy: uidAdmin,
  });

  // ── 4. DOCUMENTE ──────────────────────────────────────────────────────────
  console.log('\n▸ 4/6  Documente...');

  await setDoc('documents', 'doc_1', {
    propertyId: 'prop_spatiu_1', denumire: 'HCL nr. 45/2024 — Aprobare închiriere spațiu comercial',
    tip: 'hcl', status: 'verificat',
    numarDocument: '45/2024', dataDocument: d(2024, 3, 28),
    emitent: 'Consiliul Local Cluj-Napoca',
    descriere: 'Hotărâre de consiliu local privind aprobarea închirierii spațiului comercial.',
    fileUrl: null, fileSize: null,
    createdAt: d(2024, 3, 29), createdBy: uidAdmin,
  });
  await setDoc('documents', 'doc_2', {
    propertyId: 'prop_cladire_1', denumire: 'Extras Carte Funciară — Clădire Piața Unirii',
    tip: 'extrasCF', status: 'verificat',
    numarDocument: 'CF 312450', dataDocument: d(2024, 1, 10),
    emitent: 'OCPI Cluj',
    descriere: 'Extras CF actualizat pentru imobilul administrativ Piața Unirii nr. 1.',
    fileUrl: null, fileSize: null,
    createdAt: d(2024, 1, 12), createdBy: uidFunc,
  });
  await setDoc('documents', 'doc_3', {
    propertyId: 'prop_teren_1', denumire: 'Plan Cadastral — Teren Str. Florilor nr. 12',
    tip: 'planCadastral', status: 'verificat',
    numarDocument: 'PC 318452/2023', dataDocument: d(2023, 10, 5),
    emitent: 'ANCPI',
    descriere: 'Plan cadastral actualizat pentru terenul intravilan Str. Florilor.',
    fileUrl: null, fileSize: null,
    createdAt: d(2023, 10, 8), createdBy: uidAdmin,
  });
  await setDoc('documents', 'doc_4', {
    propertyId: 'prop_spatiu_2', denumire: 'Raport de evaluare — Spațiu birou Sala B201',
    tip: 'raportEvaluare', status: 'inVerificare',
    numarDocument: 'RE-2024-042', dataDocument: d(2024, 5, 10),
    emitent: 'SC Evaluări Imobiliare SRL',
    descriere: 'Raport de evaluare la valoarea de piață a spațiului de birouri B201.',
    fileUrl: null, fileSize: null,
    createdAt: d(2024, 5, 12), createdBy: uidFunc,
  });
  await setDoc('documents', 'doc_5', {
    propertyId: 'prop_spatiu_1', denumire: 'Contract de Închiriere nr. 456/2024',
    tip: 'contract', status: 'neverificat',
    numarDocument: '456/2024', dataDocument: d(2024, 5, 1),
    emitent: 'Primăria Cluj-Napoca',
    descriere: 'Contract de închiriere spațiu comercial — SC TechHub SRL, 2 ani.',
    fileUrl: null, fileSize: null,
    createdAt: d(2024, 5, 1), createdBy: uidAdmin,
  });
  await setDoc('documents', 'doc_6', {
    propertyId: 'prop_teren_1', denumire: 'Contract de Concesionare nr. 123/2023',
    tip: 'contract', status: 'neverificat',
    numarDocument: '123/2023', dataDocument: d(2023, 12, 1),
    emitent: 'Primăria Cluj-Napoca',
    descriere: 'Contract de concesionare teren Str. Florilor — SC Urban Green SRL, 25 ani.',
    fileUrl: null, fileSize: null,
    createdAt: d(2023, 12, 2), createdBy: uidAdmin,
  });

  // ── 5. CONTRACTE ──────────────────────────────────────────────────────────
  console.log('\n▸ 5/6  Contracte...');

  await setDoc('contracts', 'contract_1', {
    propertyId: 'prop_spatiu_1', propertyDenumire: 'Spațiu comercial parter Bloc A2 ap. 1',
    transactionId: 'trx_1',
    numarContract: '456/2024',
    parteContractanta: 'SC TechHub SRL',
    dataInceput: d(2024, 5, 1), dataFinal: d(2026, 5, 1),
    valoare: 1800.0, valutaMoneda: 'RON',
    status: 'activ',
    documentUrl: null,
    note: 'Chirie lunară 1800 RON, indexare anuală CPI. Garanție 2 luni plătită.',
    createdAt: d(2024, 5, 1), createdBy: uidAdmin,
  });
  await setDoc('contracts', 'contract_2', {
    propertyId: 'prop_teren_1', propertyDenumire: 'Teren intravilan Str. Florilor nr. 12',
    transactionId: 'trx_3',
    numarContract: '123/2023',
    parteContractanta: 'SC Urban Green SRL',
    dataInceput: d(2023, 12, 1), dataFinal: d(2048, 12, 1),
    valoare: 3600.0, valutaMoneda: 'RON',
    status: 'activ',
    documentUrl: null,
    note: 'Redevență anuală 3600 RON. Concesionar obligat să amenajeze loc de joacă în 12 luni.',
    createdAt: d(2023, 12, 2), createdBy: uidAdmin,
  });

  // ── 6. LICITAȚIE ACTIVĂ + OFERTE ─────────────────────────────────────────
  console.log('\n▸ 6/6  Licitație și oferte...');

  await setDoc('auctions', 'auction_1', {
    propertyId: 'prop_spatiu_2', propertyDenumire: 'Spațiu birou etaj 2 Primărie — Sala B201',
    titlu: 'Licitație publică — Închiriere Spațiu Birou Sala B201',
    tipAtribuire: 'inchiriere',
    pretPornire: 3000.0, pasLicitare: 100.0, garantieParticipare: 600.0,
    dataInceput: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 3),
    dataFinal: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() + 7),
    status: 'activa',
    castigatorId: null, castigatorNume: null, ofertaCastigatoare: null,
    transactionId: null, contractId: null,
    descriere: 'Închiriere birou 120 mp, etaj 2, clădire Primărie. Acces internet, parcare. ' +
               'Destinație: birouri sau servicii cu publicul. Durată: 3 ani.',
    documentIds: ['doc_4'],
    createdAt: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 5),
    createdBy: uidAdmin,
  });

  // Participanți la licitație
  await setDoc('auction_participants', 'part_1', {
    auctionId: 'auction_1', userId: uidExt1,
    numeParticipant: 'Andrei Constantin',
    dataInregistrare: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 3),
    garantiePlatita: true, documenteDepuse: true,
    createdAt: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 3),
  });
  await setDoc('auction_participants', 'part_2', {
    auctionId: 'auction_1', userId: uidExt2,
    numeParticipant: 'Elena Dumitrescu',
    dataInregistrare: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 2),
    garantiePlatita: true, documenteDepuse: true,
    createdAt: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 2),
  });
  await setDoc('auction_participants', 'part_3', {
    auctionId: 'auction_1', userId: uidExt3,
    numeParticipant: 'Mihai Popa',
    dataInregistrare: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 1),
    garantiePlatita: true, documenteDepuse: false,
    createdAt: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 1),
  });

  // Oferte (bids)
  await setDoc('bids', 'bid_1', {
    auctionId: 'auction_1', participantId: uidExt1,
    participantNume: 'Andrei Constantin',
    valoare: 3200.0,
    dataOra: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 2, 10, 15, 0),
    validata: true, respinsa: false, motivRespingere: null,
  });
  await setDoc('bids', 'bid_2', {
    auctionId: 'auction_1', participantId: uidExt2,
    participantNume: 'Elena Dumitrescu',
    valoare: 3500.0,
    dataOra: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate() - 1, 14, 30, 0),
    validata: true, respinsa: false, motivRespingere: null,
  });
  await setDoc('bids', 'bid_3', {
    auctionId: 'auction_1', participantId: uidExt3,
    participantNume: 'Mihai Popa',
    valoare: 3800.0,
    dataOra: new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate(), 9, 0, 0),
    validata: false, respinsa: false, motivRespingere: null,
  });

  // ─────────────────────────────────────────────────────────────────────────
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║  ✓  Seed complet! Firestore populat.      ║');
  console.log('╚══════════════════════════════════════════╝');
  console.log('\nConturi create:');
  console.log('  admin@epatrimoniu.ro          / Admin1234!');
  console.log('  functionar@epatrimoniu.ro     / Functionar1234!');
  console.log('  participant1@epatrimoniu.ro   / Participant1234!');
  console.log('  participant2@epatrimoniu.ro   / Participant1234!');
  console.log('  participant3@epatrimoniu.ro   / Participant1234!\n');
}

seed().catch(err => {
  console.error('\n✗ Eroare:', err.message);
  process.exit(1);
});
