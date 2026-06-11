'use strict';

const express = require('express');
const { db, auth } = require('../firebase');
const { verifyToken, requireAdmin } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

// GET /api/users — admin only
router.get('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const snap = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json(users);
  } catch (err) {
    console.error('GET /users:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/users/me — orice utilizator autentificat
router.get('/me', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'Utilizator negăsit.' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/users/register — creare cont nou
// Un utilizator neautentificat poate crea un cont extern.
// Un admin poate crea conturi cu orice rol.
router.post('/register', async (req, res) => {
  const { email, password, firstName, lastName, phone, role, departament } = req.body;

  if (!email || !password || !firstName || !lastName) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: email, password, firstName, lastName.' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Parola trebuie să aibă minim 8 caractere.' });
  }

  // Determine if caller is an authenticated admin
  let callerIsAdmin = false;
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const decoded = await auth.verifyIdToken(authHeader.split('Bearer ')[1], true);
      const callerDoc = await db.collection('users').doc(decoded.uid).get();
      callerIsAdmin = callerDoc.exists && callerDoc.data().role === 'administrator';
    } catch (_) { /* unauthenticated or invalid token — treat as non-admin */ }
  }

  // Enforce role cap: non-admins can only register as 'extern'
  const effectiveRole = callerIsAdmin ? (role ?? 'extern') : 'extern';
  if (!callerIsAdmin && role && role !== 'extern') {
    return res.status(403).json({ error: 'Acces interzis: numai adminii pot crea conturi cu rol privilegiat.' });
  }

  try {
    const userRecord = await auth.createUser({ email, password, displayName: `${firstName} ${lastName}`.trim() });

    await db.collection('users').doc(userRecord.uid).set({
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: (phone ?? '').trim(),
      role: effectiveRole,
      status: 'activ',
      departament: departament ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Send email verification via Firebase Auth
    // (Firebase Admin SDK cannot send verification email directly;
    //  the client app must call user.sendEmailVerification() after login)

    res.status(201).json({ uid: userRecord.uid, role: effectiveRole });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      return res.status(409).json({ error: 'Acest email este deja înregistrat.' });
    }
    if (err.code === 'auth/invalid-password') {
      return res.status(400).json({ error: 'Parola nu respectă cerințele minime.' });
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
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'modificare', entitate: 'Utilizator', entitateId: uid,
      detalii: `Rol actualizat → ${role}`,
    });
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
    return res.status(400).json({ error: `Status invalid. Valori permise: ${validStatuses.join(', ')}.` });
  }

  try {
    await db.collection('users').doc(uid).update({ status });

    // If disabling user, revoke all Firebase Auth sessions
    if (status !== 'activ') {
      await auth.revokeRefreshTokens(uid);
    }

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Utilizator', entitateId: uid,
      detalii: `Status actualizat → ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /users/:uid/status:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
