// generate_comparison_table.js
// Genereaza tabelul de comparatie securitate pentru teza de licenta
// Rulare: node generate_comparison_table.js

const { execSync } = require('child_process');
const path = require('path');
const fs   = require('fs');

// ── Instaleaza xlsx daca lipseste ─────────────────────────────────────────────
try {
  require.resolve('xlsx');
} catch {
  console.log('Instalez dependenta xlsx...');
  execSync('npm install xlsx', { stdio: 'inherit' });
}

const XLSX = require('xlsx');

// ── Date vulnerabilitati identificate in cod ──────────────────────────────────
// Coloana "Identificata de" este lasata goala — o completezi dupa ce rulezi promptul
// pe ChatGPT, Claude si Gemini.
const VULNS = [
  {
    nr: 1,
    vulnerabilitate: 'Cheie API Gemini hardcodată în bundle JS',
    fisier_linie: 'ai_service.dart:74',
    owasp: 'A02 – Cryptographic Failures',
    cwe: 'CWE-798',
    asvs: 'V6.4.1',
    descriere: 'Constanta Dart compilată în dart2js este vizibilă în DevTools/Sources.',
  },
  {
    nr: 2,
    vulnerabilitate: 'Cheie API în URL query string (rețea/loguri)',
    fisier_linie: 'ai_service.dart:122-124',
    owasp: 'A02 – Cryptographic Failures',
    cwe: 'CWE-598',
    asvs: 'V6.4.1',
    descriere: '`?key=$_apiKey` apare în URL — locat în loguri server și history browser.',
  },
  {
    nr: 3,
    vulnerabilitate: 'Enumerare utilizatori prin mesaje de eroare',
    fisier_linie: 'auth_service.dart:220-221',
    owasp: 'A07 – Identification and Authentication Failures',
    cwe: 'CWE-204',
    asvs: 'V2.2.2',
    descriere: 'Mesaje distincte "user-not-found" vs "wrong-password" permit enumerarea conturilor.',
  },
  {
    nr: 4,
    vulnerabilitate: 'Scurgere cod eroare autentificare brut',
    fisier_linie: 'auth_service.dart:228',
    owasp: 'A07 – Identification and Authentication Failures',
    cwe: 'CWE-209',
    asvs: 'V14.3.2',
    descriere: 'Cazul `default` returnează `"Cod: $code"` cu valoarea internă Firebase.',
  },
  {
    nr: 5,
    vulnerabilitate: 'Parola trimmed — reducere entropie',
    fisier_linie: 'auth_service.dart:48',
    owasp: 'A07 – Identification and Authentication Failures',
    cwe: 'CWE-521',
    asvs: 'V2.1.1',
    descriere: '`password.trim()` elimină spații semnificative din parole înainte de autentificare.',
  },
  {
    nr: 6,
    vulnerabilitate: 'Cont activat fără verificare email',
    fisier_linie: 'users.js:75 / auth_service.dart:93',
    owasp: 'A07 – Identification and Authentication Failures',
    cwe: 'CWE-306',
    asvs: 'V2.1.13',
    descriere: 'Status `activ` setat imediat la înregistrare fără a verifica adresa de email.',
  },
  {
    nr: 7,
    vulnerabilitate: 'Lipsă rate limiting pe toate endpoint-urile',
    fisier_linie: 'index.js (global)',
    owasp: 'A04 – Insecure Design',
    cwe: 'CWE-770',
    asvs: 'V4.2.2',
    descriere: 'Niciun middleware de rate limiting — permite brute force și flooding nerestricționat.',
  },
  {
    nr: 8,
    vulnerabilitate: 'CORS permite cereri fără header Origin',
    fisier_linie: 'index.js:29-30',
    owasp: 'A05 – Security Misconfiguration',
    cwe: 'CWE-346',
    asvs: 'V14.5.3',
    descriere: '`if (!origin)` acceptă orice cerere fără Origin — bypassează protecția CORS.',
  },
  {
    nr: 9,
    vulnerabilitate: 'Mesaje chat fără validare proprietar sesiune',
    fisier_linie: 'ai_service.dart:196-202 / saveMessage',
    owasp: 'A01 – Broken Access Control',
    cwe: 'CWE-639',
    asvs: 'V4.2.1',
    descriere: '`getMessages(sessionId)` și `deleteSession` nu verifică dacă sesiunea aparține utilizatorului.',
  },
  {
    nr: 10,
    vulnerabilitate: 'Toți utilizatorii pot vizualiza toate scanările',
    fisier_linie: 'scan_service.dart:175-180',
    owasp: 'A01 – Broken Access Control',
    cwe: 'CWE-284',
    asvs: 'V4.1.3',
    descriere: '`getAll()` returnează toate scan_tasks fără filtrare după userId sau rol.',
  },
  {
    nr: 11,
    vulnerabilitate: 'markVerified/updateFields fără verificare rol',
    fisier_linie: 'scan_service.dart:167-173',
    owasp: 'A01 – Broken Access Control',
    cwe: 'CWE-285',
    asvs: 'V4.1.2',
    descriere: 'Orice utilizator autentificat poate marca o scanare ca verificată sau modifica câmpurile extrase.',
  },
  {
    nr: 12,
    vulnerabilitate: 'Licitații — ofertele tuturor participanților vizibile',
    fisier_linie: 'auctions.js:150-159',
    owasp: 'A01 – Broken Access Control',
    cwe: 'CWE-284',
    asvs: 'V4.1.3',
    descriere: 'GET /bids returnează participantId, participantNume, valoare pentru toți — date sensibile licitație.',
  },
  {
    nr: 13,
    vulnerabilitate: 'Eșec audit log înghițit silențios',
    fisier_linie: 'audit.js:22-24',
    owasp: 'A09 – Security Logging and Monitoring Failures',
    cwe: 'CWE-778',
    asvs: 'V7.1.1',
    descriere: '`try/catch` în `writeAuditLog` loghează doar la consolă — eșecul auditului nu alertează.',
  },
  {
    nr: 14,
    vulnerabilitate: 'Login eșuat neînregistrat în audit log',
    fisier_linie: 'auth_service.dart:61-63',
    owasp: 'A09 – Security Logging and Monitoring Failures',
    cwe: 'CWE-223',
    asvs: 'V7.2.1',
    descriere: 'Autentificările eșuate nu sunt înregistrate — atacurile de tip brute force rămân nevăzute.',
  },
  {
    nr: 15,
    vulnerabilitate: 'URL backend HTTP ca valoare implicită',
    fisier_linie: 'app_config.dart:35-38',
    owasp: 'A02 – Cryptographic Failures',
    cwe: 'CWE-319',
    asvs: 'V9.1.1',
    descriere: '`defaultValue: http://localhost:10000` — traficul nu este criptat dacă BACKEND_URL lipsește.',
  },
];

// ── Construieste workbook ─────────────────────────────────────────────────────
const wb = XLSX.utils.book_new();

// ─── Sheet 1: Tabel Comparativ ───────────────────────────────────────────────
const compRows = [];

// Header principal
compRows.push([
  'Nr.', 'Vulnerabilitate', 'Fișier : Linie',
  'OWASP Top 10 2025', 'CWE', 'ASVS v5.0.0',
  'Descriere scurtă',
  // Claude
  'Claude — Identificată?', 'Claude — Severitate', 'Claude — Scor CVSS', 'Claude — Vector CVSS', 'Claude — Remediere',
  // ChatGPT
  'ChatGPT — Identificată?', 'ChatGPT — Severitate', 'ChatGPT — Scor CVSS', 'ChatGPT — Vector CVSS', 'ChatGPT — Remediere',
  // Gemini
  'Gemini — Identificată?', 'Gemini — Severitate', 'Gemini — Scor CVSS', 'Gemini — Vector CVSS', 'Gemini — Remediere',
  // Analiza
  'Găsită de (nr. AI)', 'Concluzie comparativă',
]);

for (const v of VULNS) {
  compRows.push([
    v.nr, v.vulnerabilitate, v.fisier_linie,
    v.owasp, v.cwe, v.asvs,
    v.descriere,
    '', '', '', '', '',   // Claude — de completat
    '', '', '', '', '',   // ChatGPT — de completat
    '', '', '', '', '',   // Gemini — de completat
    `=COUNTIF(H${v.nr+1},"Da")+COUNTIF(M${v.nr+1},"Da")+COUNTIF(R${v.nr+1},"Da")`,
    '',
  ]);
}

const wsComp = XLSX.utils.aoa_to_sheet(compRows);

// Latime coloane
const colWidths = [
  { wch: 5 },   // Nr
  { wch: 42 },  // Vulnerabilitate
  { wch: 30 },  // Fisier
  { wch: 40 },  // OWASP
  { wch: 10 },  // CWE
  { wch: 12 },  // ASVS
  { wch: 55 },  // Descriere
  // Claude
  { wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 40 }, { wch: 45 },
  // ChatGPT
  { wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 40 }, { wch: 45 },
  // Gemini
  { wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 40 }, { wch: 45 },
  { wch: 16 }, { wch: 40 },
];
wsComp['!cols'] = colWidths;

// Freeze prima coloana + header
wsComp['!freeze'] = { xSplit: 1, ySplit: 1 };

XLSX.utils.book_append_sheet(wb, wsComp, 'Tabel Comparativ');

// ─── Sheet 2: Rezultate Claude ──────────────────────────────────────────────
const claudeHeader = [
  'Nr.', 'Vulnerabilitate', 'Fișier : Linie',
  'OWASP Top 10 2025', 'CWE', 'ASVS v5.0.0',
  'Severitate', 'Scor CVSS v3.1', 'Vector CVSS v3.1',
  'Descriere scurtă', 'Remediere propusă',
];
const wsC = XLSX.utils.aoa_to_sheet([claudeHeader]);
wsC['!cols'] = [
  {wch:5},{wch:42},{wch:30},{wch:38},{wch:10},{wch:12},
  {wch:12},{wch:10},{wch:42},{wch:55},{wch:55},
];
XLSX.utils.book_append_sheet(wb, wsC, 'Rezultate Claude');

// ─── Sheet 3: Rezultate ChatGPT ─────────────────────────────────────────────
const wsGPT = XLSX.utils.aoa_to_sheet([claudeHeader]);
wsGPT['!cols'] = wsC['!cols'];
XLSX.utils.book_append_sheet(wb, wsGPT, 'Rezultate ChatGPT');

// ─── Sheet 4: Rezultate Gemini ───────────────────────────────────────────────
const wsGem = XLSX.utils.aoa_to_sheet([claudeHeader]);
wsGem['!cols'] = wsC['!cols'];
XLSX.utils.book_append_sheet(wb, wsGem, 'Rezultate Gemini');

// ─── Sheet 5: Instructiuni ───────────────────────────────────────────────────
const instructions = [
  ['GHID DE UTILIZARE — Tabel Comparativ Securitate e-Patrimoniu'],
  [''],
  ['PASUL 1 — Trimite promptul'],
  ['  Deschide SECURITY_REVIEW_PROMPT_v2.md, copiaza continutul si trimite-l pe rand la:'],
  ['  - Claude (claude.ai)'],
  ['  - ChatGPT (chatgpt.com)'],
  ['  - Gemini (gemini.google.com)'],
  [''],
  ['PASUL 2 — Copiaza tabelul de raspuns'],
  ['  Fiecare AI va genera un tabel Markdown cu coloanele cerute in prompt.'],
  ['  Copiaza randul de date din tabelul Markdown in sheet-ul corespunzator:'],
  ['  - Raspuns Claude   → sheet "Rezultate Claude"'],
  ['  - Raspuns ChatGPT  → sheet "Rezultate ChatGPT"'],
  ['  - Raspuns Gemini   → sheet "Rezultate Gemini"'],
  [''],
  ['PASUL 3 — Completeaza Tabelul Comparativ'],
  ['  In sheet-ul "Tabel Comparativ", pentru fiecare vulnerabilitate din lista:'],
  ['  - Coloana "Identificata?" → scrie "Da" sau "Nu"'],
  ['  - Coloana "Severitate"    → copiaza din raspunsul AI (Critical/High/Medium/Low)'],
  ['  - Coloana "Scor CVSS"     → copiaza scorul numeric (ex: 7.5)'],
  ['  - Coloana "Vector CVSS"   → copiaza vectorul complet'],
  ['  - Coloana "Remediere"     → scrie pe scurt remedierea propusa de AI'],
  [''],
  ['PASUL 4 — Analiza comparativa'],
  ['  Coloana "Gasita de (nr. AI)" se calculeaza automat (formula COUNTIF).'],
  ['  Completeaza "Concluzie comparativa" cu observatii proprii:'],
  ['  ex: "Toti 3 AI au identificat-o cu severitate diferita" sau'],
  ['      "Doar Claude a identificat-o, celelalte 2 au ratat-o"'],
  [''],
  ['IMPORTANT PENTRU TEZA'],
  ['  - Vulnerabilitatile pre-populate (nr. 1-15) sunt reale, gasite in codul aplicatiei.'],
  ['  - Daca un AI gaseste vulnerabilitati suplimentare, adauga randuri noi.'],
  ['  - Coloanele OWASP, CWE, ASVS sunt pre-completate cu valorile corecte —'],
  ['    compara daca AI-urile citeaza aceleasi standarde sau altele.'],
];
const wsI = XLSX.utils.aoa_to_sheet(instructions);
wsI['!cols'] = [{ wch: 90 }];
XLSX.utils.book_append_sheet(wb, wsI, 'Instructiuni');

// ── Salveaza fisierul ─────────────────────────────────────────────────────────
const outPath = path.join(__dirname, 'Comparatie_Securitate_ePatrimoniu.xlsx');
XLSX.writeFile(wb, outPath);
console.log(`\nFisier generat: Comparatie_Securitate_ePatrimoniu.xlsx`);
console.log('Deschide-l in Excel pentru a completa rezultatele celor 3 AI.\n');
