# Security Code Review Prompt — e-Patrimoniu
# Teză de licență: Testarea securității aplicațiilor web
# Versiune: 2.0 — cod real, organizat pe categorii OWASP Top 10 2025
# Utilizabil pe: ChatGPT, Claude, Gemini, Copilot sau orice AI capabil de raționament tehnic

---

You are a senior application security engineer performing a security code review.
The output will be reviewed by an AppSec lead who will reject it if:
- findings are imprecise or not grounded in the provided code
- standards are cited without justification
- remediation introduces new risks
- findings are invented or not present in the code

Work through the review in this exact order. Show security rationale, evidence
(exact file + line reference), and explicit assumptions for each step.

---

## CONTEXT

**Application:** e-Patrimoniu — web application for managing real estate assets
(bunuri imobiliare) of Romanian local public administration units (UAT).
Records include cadastral numbers, land-registry numbers, inventory values (RON),
legal status, transactions, concession contracts, and public auctions.

**Stack:**
- Frontend: Flutter 3.x (Dart) compiled to JavaScript (dart2js) — deployed on Vercel.
  Key packages: firebase_auth ^6.1.2, cloud_firestore ^6.1.0,
  firebase_storage ^13.0.4, google_generative_ai ^0.4.7, http ^1.2.0,
  shared_preferences ^2.5.4, hive ^2.2.3.
- Backend: Node.js 18 + Express 4 — deployed on Render (Frankfurt, free tier).
  Key packages: firebase-admin, helmet, cors, express.
- Firebase: Authentication (email/password), Firestore, Storage.
  Firestore Security Rules are NOT in scope — treat them as a separate control.

**Authentication flow:**
Firebase Auth issues a JWT ID token (1-hour TTL). Every backend request carries
`Authorization: Bearer <idToken>`. Backend middleware calls
`auth.verifyIdToken(token, true)` (checkRevoked=true), then reads the Firestore
`users` collection to get live role and account status.
Three roles: `administrator`, `functionar`, `extern`.

**Data sensitivity:**
- HIGH: cadastral/land-registry numbers, inventory values, auction financial data,
  legal dispute status of properties.
- MEDIUM: personal data of civil servants and external users (name, email, phone)
  — GDPR Article 4.
- LOW: audit log entries.

**Deployment facts relevant to security:**
- Flutter web build: `flutter build web --release --dart-define=BACKEND_URL=...`
  Dart `const String.fromEnvironment` values are inlined at compile time into
  the JS bundle and are visible in browser DevTools → Sources.
- `shared_preferences` on Flutter Web uses `window.localStorage`. Any value
  written there is readable by JavaScript running on the same origin.
- No WAF, no CDN-level rate limiting, no CAPTCHA anywhere in the stack.
- Render free tier spins down after inactivity (cold start ~30s).

**Relevant standards:**
- OWASP Top 10 2025
- OWASP ASVS v5.0.0
- CWE
- CVSS v3.1
- GDPR (EU) 2016/679
- NIS2 Directive (EU) 2022/2555
- Romanian Law 363/2018

**Threat actors:**
1. Unauthenticated network attacker — account takeover, user enumeration,
   registration abuse, API key extraction from JS bundle.
2. Authenticated low-privilege user (role: `extern`) — privilege escalation,
   access to other users' data, auction bid manipulation.
3. Malicious insider (role: `functionar`) — exfiltration of property records,
   manipulation of inventory values without audit trace.
4. Automated bot — credential stuffing, API quota exhaustion.

---

## CONSTRAINTS

- Merge findings that share a root cause. Do not list symptoms separately.
- Do not invent code paths outside the snippets provided.
- If a control belongs to Firestore Security Rules, WAF, or IdP — name it, state
  out of scope, stop.
- If severity depends on unseen context, give a range and state the dependency.

---

## REVIEW STEPS

**STEP 1 — Threat model.**
For each code group below, enumerate: trust boundaries crossed, attacker
capabilities in scope, STRIDE categories applicable.

**STEP 2 — Map findings to standards.**
For each finding: CWE, OWASP ASVS v5.0.0 section, OWASP Top 10 2025 category,
and GDPR/NIS2 article if applicable.

**STEP 3 — Rate exploitability.**
CVSS v3.1 vector string per finding. State assumptions explicitly.

**STEP 4 — Remediated implementation.**
Rewrite each vulnerable snippet. Requirements:
- Preserve intended functionality
- Add input validation, enforce authz, use safe error handling
- No information leakage, secure defaults
- Runnable as written — no invented APIs
- If a library is needed, name a real one

**STEP 5 — Red-team your own fix.**
Three ways each fix can still fail in production + detection/compensating control.

**Output format:**
1. Threat model
2. Findings mapped to standards
3. Exploitability ratings
4. Remediated implementation
5. Red-team review
6. Final recommendations

---

# CODE TO REVIEW

---

## GROUP 1 — Authentication & Session (OWASP candidates: A07, A02)

### FILE: lib/core/services/auth_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user_model.dart';
import '../config/app_config.dart';
import 'audit_service.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),    // <-- line 48
      );
      final user = cred.user;
      if (user != null) {
        await _saveLocalUser(user);
        await AuditService.log(
          userId: user.uid,
          userName: user.displayName ?? email,
          actiune: AuditAction.autentificare,
          entitate: 'Sesiune',
          detalii: 'Autentificare reușită',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  static Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    String? departament,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),    // <-- password trimmed here too
      );
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName('$firstName $lastName'.trim());
        await _firestore.collection(AppConfig.colUsers).doc(user.uid).set({
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role.name,             // role passed directly from client
          'status': UserStatus.activ.name,
          'departament': departament,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _saveLocalUser(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      final actionSettings = ActionCodeSettings(
        url: 'https://epatrimoniu.ro/reset-password',
        handleCodeInApp: false,
      );
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionSettings,
      );
    } on FirebaseAuthException catch (e) {
      // Fallback — retries WITHOUT actionCodeSettings if domain not configured
      try {
        await _auth.sendPasswordResetEmail(email: email.trim());
      } catch (_) {
        throw Exception(_mapAuthError(e.code));
      }
    }
  }

  // No email verification check before granting access anywhere in this service
  static Future<UserRole> getCurrentUserRole() async {
    final model = await getCurrentUserModel();
    return model?.role ?? UserRole.extern;
  }

  static Future<void> updateUserRole(String uid, UserRole role) async {
    // Direct Firestore write — no server-side authorization check in this method
    await _firestore
        .collection(AppConfig.colUsers)
        .doc(uid)
        .update({'role': role.name});
  }

  static Future<void> updateUserStatus(String uid, UserStatus status) async {
    // Direct Firestore write — no server-side authorization check in this method
    await _firestore
        .collection(AppConfig.colUsers)
        .doc(uid)
        .update({'status': status.name});
  }

  static Future<void> _saveLocalUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('displayName', user.displayName ?? '');
    await prefs.setString('email', user.email ?? '');
    // On Flutter Web, SharedPreferences uses window.localStorage
  }

  static String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':        return 'Adresa de email nu este validă.';
      case 'user-not-found':       return 'Nu există un cont cu acest email.';  // <-- line 220
      case 'wrong-password':       return 'Parola este incorectă.';             // <-- line 221
      case 'user-disabled':        return 'Acest cont a fost dezactivat.';
      case 'email-already-in-use': return 'Acest email este deja folosit.';
      case 'weak-password':        return 'Parola trebuie să aibă minim 6 caractere.';
      case 'too-many-requests':    return 'Prea multe încercări. Reîncercați mai târziu.';
      case 'network-request-failed': return 'Eroare de rețea. Verificați conexiunea.';
      default: return 'Eroare de autentificare. Cod: $code';   // <-- leaks raw code
    }
  }
}
```

---

## GROUP 2 — Client-side secret & AI integration (OWASP candidates: A02, A08, A01)

### FILE: lib/core/services/ai_service.dart

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

class AiService {
  static final _firestore = FirebaseFirestore.instance;

  // Dart const — inlined into the dart2js JS bundle at compile time
  static const String _apiKey = 'INSEREAZA_CHEIA_TA_API_GEMINI_AICI';  // line 74

  static const String _systemPrompt = '''
Ești Asistentul e-Patrimoniu, specializat în evidența bunurilor imobiliare ale UAT.
Ești DOAR informativ. Nu modifici date, nu creezi sau ștergi înregistrări.
Răspunde ÎNTOTDEAUNA în limba română.
''';

  static Future<String> sendMessage(
    String userMessage,        // no length cap
    List<ChatMessage> history,
  ) async {
    final contents = <Map<String, dynamic>>[];

    // Last 10 messages appended verbatim — no sanitization or length cap
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.content}],    // raw content, no sanitization
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    // API key appended in URL query string — visible in network tab and server logs
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {'parts': [{'text': _systemPrompt}]},
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2000,
          'topP': 0.9,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      return 'Eroare la comunicarea cu asistentul (${response.statusCode}).';
    }
  }

  // Sessions filtered only by userId — client provides its own UID
  static Stream<List<ChatSession>> getSessions(String userId) {
    return _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatSession.fromFirestore(d)).toList());
  }

  // No check that sessionId belongs to the authenticated user
  static Stream<List<ChatMessage>> getMessages(String sessionId) {
    return _firestore
        .collection('chat_messages')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromFirestore(d)).toList());
  }

  static Future<void> saveMessage(ChatMessage msg) async {
    await _firestore.collection('chat_messages').add(msg.toFirestore());
    if (msg.isUser) {
      // Title is raw user input, truncated — no sanitization
      final title = msg.content.length > 50
          ? '${msg.content.substring(0, 50)}...'
          : msg.content;
      await _firestore.collection('chat_sessions').doc(msg.sessionId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'title': title,
      });
      // No check that msg.sessionId belongs to the calling user
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    final msgs = await _firestore
        .collection('chat_messages')
        .where('sessionId', isEqualTo: sessionId)
        .get();
    for (final doc in msgs.docs) {
      await doc.reference.delete();  // no ownership check before deletion
    }
    await _firestore.collection('chat_sessions').doc(sessionId).delete();
  }
}
```

---

## GROUP 3 — Registration & user management (OWASP candidates: A07, A01, A04)

### FILE: backend/routes/users.js

```javascript
'use strict';
const express  = require('express');
const { db, auth } = require('../firebase');
const { verifyToken, requireAdmin } = require('../middleware/auth');
const { FieldValue } = require('firebase-admin/firestore');
const router = express.Router();

// GET /api/users — admin only
router.get('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const snap = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json(users);   // returns all fields including phone, departament, status
  } catch (err) {
    console.error('GET /users:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/users/register — open to unauthenticated callers
router.post('/register', async (req, res) => {
  const { email, password, firstName, lastName, phone, role, departament } = req.body;

  // Validation: only presence + minimum length
  if (!email || !password || !firstName || !lastName) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: email, password, firstName, lastName.' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Parola trebuie să aibă minim 8 caractere.' });
  }
  // No: email format validation, name length cap, phone format/length check,
  // input sanitization, rate limiting, CAPTCHA

  let callerIsAdmin = false;
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const decoded = await auth.verifyIdToken(authHeader.split('Bearer ')[1], true);
      const callerDoc = await db.collection('users').doc(decoded.uid).get();
      callerIsAdmin = callerDoc.exists && callerDoc.data().role === 'administrator';
    } catch (_) { /* silent — bad/expired token treated as unauthenticated */ }
  }

  const effectiveRole = callerIsAdmin ? (role ?? 'extern') : 'extern';
  if (!callerIsAdmin && role && role !== 'extern') {
    return res.status(403).json({ error: 'Acces interzis.' });
  }

  try {
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`.trim(),
    });

    await db.collection('users').doc(userRecord.uid).set({
      firstName: firstName.trim(),
      lastName:  lastName.trim(),
      email:     email.trim().toLowerCase(),
      phone:     (phone ?? '').trim(),
      role:      effectiveRole,
      status:    'activ',    // account active immediately — no email verification step
      departament: departament ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    res.status(201).json({ uid: userRecord.uid, role: effectiveRole });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      return res.status(409).json({ error: 'Acest email este deja înregistrat.' }); // user enumeration
    }
    console.error('POST /users/register:', err);
    res.status(500).json({ error: 'Eroare la crearea contului.' });
  }
});

// PUT /api/users/:uid/role — admin only
router.put('/:uid/role', verifyToken, requireAdmin, async (req, res) => {
  const { uid } = req.params;
  const { role } = req.body;
  const validRoles = ['administrator', 'functionar', 'extern'];

  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: `Rol invalid. Valori permise: ${validRoles.join(', ')}.` });
  }

  try {
    await db.collection('users').doc(uid).update({ role });
    // No check that uid exists before update — Firestore will create fields on non-existent doc
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /users/:uid/role:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/users/:uid/status — admin only
router.put('/:uid/status', verifyToken, requireAdmin, async (req, res) => {
  const { uid } = req.params;
  const { status } = req.body;
  const validStatuses = ['activ', 'inactiv', 'suspendat'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: `Status invalid.` });
  }

  try {
    await db.collection('users').doc(uid).update({ status });
    if (status !== 'activ') {
      await auth.revokeRefreshTokens(uid);
    }
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /users/:uid/status:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
```

---

## GROUP 4 — Server configuration & middleware (OWASP candidates: A05, A04, A09)

### FILE: backend/index.js

```javascript
'use strict';
const express = require('express');
const helmet  = require('helmet');
const cors    = require('cors');
// No rate-limit, no hpp, no request-id middleware

const app  = express();
const PORT = process.env.PORT || 10000;

app.use(helmet());

const rawOrigins = (process.env.ALLOWED_ORIGIN ?? 'http://localhost:5000')
  .split(',').map(s => s.trim());

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || rawOrigins.includes(origin)) return callback(null, true); // line 29-30
    callback(new Error(`CORS: origin not allowed: ${origin}`));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '1mb' }));

app.use('/api/users',        usersRouter);
app.use('/api/properties',   propertiesRouter);
app.use('/api/transactions', transactionsRouter);
app.use('/api/contracts',    contractsRouter);
app.use('/api/auctions',     auctionsRouter);
app.use('/api/documents',    documentsRouter);

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'e-patrimoniu-api', timestamp: new Date().toISOString() });
});

app.use((_req, res) => res.status(404).json({ error: 'Endpoint negăsit.' }));

app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Eroare internă server.' });
});

app.listen(PORT, () => console.log(`e-Patrimoniu API listening on port ${PORT}`));
```

### FILE: backend/middleware/auth.js

```javascript
'use strict';
const { auth, db } = require('../firebase');

async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de autentificare lipsă.' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const decoded = await auth.verifyIdToken(token, true);
    req.uid = decoded.uid;

    const userSnap = await db.collection('users').doc(decoded.uid).get();
    if (!userSnap.exists) {
      return res.status(403).json({ error: 'Utilizator negăsit în sistem.' });
    }

    const userData = userSnap.data();
    if (userData.status !== 'activ') {
      return res.status(403).json({ error: 'Contul este dezactivat sau suspendat.' });
    }

    req.userRole = userData.role;
    req.userName = userData.firstName
      ? `${userData.firstName} ${userData.lastName}`.trim()
      : (decoded.email ?? decoded.uid);

    next();
  } catch (err) {
    if (err.code === 'auth/id-token-revoked') {
      return res.status(401).json({ error: 'Sesiunea a fost revocată. Reconectați-vă.' });
    }
    if (err.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Sesiunea a expirat. Reconectați-vă.' });
    }
    console.error('verifyToken error:', err.code, err.message);
    return res.status(401).json({ error: 'Token invalid.' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.userRole)) {
      return res.status(403).json({
        error: `Acces interzis. Roluri permise: ${roles.join(', ')}.`,
      });
    }
    next();
  };
}

const requireAdmin        = requireRole('administrator');
const requireAdminOrStaff = requireRole('administrator', 'functionar');

module.exports = { verifyToken, requireRole, requireAdmin, requireAdminOrStaff };
```

### FILE: backend/utils/audit.js

```javascript
'use strict';
const { db } = require('../firebase');
const { FieldValue } = require('firebase-admin/firestore');

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
    // Audit failure silently swallowed — only logged to console
    console.error('audit_log write failed:', err.message);
  }
}

module.exports = { writeAuditLog };
```

---

## GROUP 5 — Document scanning & OCR mock (OWASP candidates: A01, A04, A09)

### FILE: lib/core/services/scan_service.dart

```dart
import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

class ScanService {
  static final _firestore = FirebaseFirestore.instance;
  static final _col = _firestore.collection(AppConfig.colScanTasks);
  static final _rng = Random();   // not cryptographically secure

  static Future<ScanResult> processDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentId,
    String? propertyId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final extracted = _mockExtraction(fileName);
    final confidence = 0.75 + _rng.nextDouble() * 0.22;

    final result = ScanResult(
      id: '',
      documentId: documentId,   // documentId from caller — no ownership check
      propertyId: propertyId,
      extractedFields: extracted,
      confidenceScore: double.parse(confidence.toStringAsFixed(2)),
      rawText: _generateMockText(extracted),
      status: ScanStatus.finalizat,
      createdAt: DateTime.now(),
      verificatManual: false,
    );

    final ref = await _col.add(result.toFirestore());
    final doc = await ref.get();
    return ScanResult.fromFirestore(doc);
  }

  // Returns ALL scan results — no filter by userId or role
  static Stream<List<ScanResult>> getAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ScanResult.fromFirestore(d)).toList());
  }

  // No role check — any authenticated user can mark a scan as verified
  static Future<void> markVerified(String id) async {
    await _col.doc(id).update({'verificatManual': true});
    // No audit log entry written here
  }

  // No role check — any authenticated user can overwrite extracted fields
  static Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await _col.doc(id).update({'extractedFields': fields, 'verificatManual': true});
    // No audit log entry written here
  }
}
```

---

## GROUP 6 — Auctions & bids (OWASP candidates: A01, A04)

### FILE: backend/routes/auctions.js (bid submission endpoint)

```javascript
// POST /api/auctions/:id/bids — any authenticated user can submit a bid
router.post('/:id/bids', verifyToken, async (req, res) => {
  const auctionId = req.params.id;
  const { valoare } = req.body;

  if (valoare == null || typeof valoare !== 'number' || valoare <= 0) {
    return res.status(400).json({ error: 'Valoarea ofertei trebuie să fie un număr pozitiv.' });
  }

  try {
    const auctionSnap = await db.collection('auctions').doc(auctionId).get();
    if (!auctionSnap.exists) return res.status(404).json({ error: 'Licitație negăsită.' });

    const auction = auctionSnap.data();

    if (auction.status !== 'activa') {
      return res.status(409).json({ error: `Licitația nu este activă. Status: ${auction.status}` });
    }

    const now = new Date();
    if (now < auction.dataInceput.toDate() || now > auction.dataFinal.toDate()) {
      return res.status(409).json({ error: 'Nu sunteți în intervalul de depunere a ofertelor.' });
    }

    if (valoare < auction.pretPornire) {
      return res.status(400).json({
        error: `Oferta (${valoare} RON) este sub prețul de pornire (${auction.pretPornire} RON).`,
      });
    }

    const overshoot = (valoare - auction.pretPornire) % auction.pasLicitare;
    if (Math.abs(overshoot) > 0.01) {
      return res.status(400).json({
        error: `Oferta trebuie să respecte pasul de licitare de ${auction.pasLicitare} RON.`,
      });
    }

    // Check participant registration
    const partSnap = await db.collection('auction_participants')
      .where('auctionId', '==', auctionId)
      .where('userId', '==', req.uid)
      .limit(1)
      .get();
    if (partSnap.empty) {
      return res.status(403).json({ error: 'Nu ești înregistrat ca participant.' });
    }

    const bidRef = await db.collection('bids').add({
      auctionId,
      participantId:   req.uid,
      participantNume: req.userName,
      valoare,
      dataOra:         FieldValue.serverTimestamp(),
      validata:        false,
      respinsa:        false,
      motivRespingere: null,
    });
    // No per-user bid rate limiting — a participant can submit unlimited bids

    res.status(201).json({ id: bidRef.id });
  } catch (err) {
    console.error('POST /auctions/:id/bids:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/bids — any authenticated user can read all bids
router.get('/:id/bids', verifyToken, async (req, res) => {
  try {
    const snap = await db.collection('bids')
      .where('auctionId', '==', req.params.id)
      .orderBy('dataOra', 'desc')
      .get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    // Returns participantId, participantNume, valoare for ALL participants
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});
```

---

## GROUP 7 — Client configuration (OWASP candidates: A02, A05)

### FILE: lib/core/config/app_config.dart

```dart
class AppConfig {
  // Inlined at compile time into the dart2js JS bundle
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:10000',  // HTTP fallback — no TLS
  );

  static const Duration connectionTimeout = Duration(seconds: 30);

  // AI enabled globally — no per-role gate
  static const bool enableAI = true;
}
```
