'use strict';

const express = require('express');
const { auth } = require('../firebase');
const { pool } = require('../db');
const { verifyToken, requireAdmin } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

// GET /api/users — admin only
router.get('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT uid AS id, "firstName", "lastName", email, phone, role, status, departament, created_at AS "createdAt" FROM users ORDER BY created_at DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error('GET /users:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/users/me — orice utilizator autentificat
router.get('/me', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT uid AS id, "firstName", "lastName", email, phone, role, status, departament, created_at AS "createdAt" FROM users WHERE uid = $1',
      [req.uid]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Utilizator negăsit.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/users/register — creare cont nou
router.post('/register', async (req, res) => {
  const { email, password, firstName, lastName, phone, role, departament } = req.body;

  if (!email || !password || !firstName || !lastName) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: email, password, firstName, lastName.' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Parola trebuie să aibă minim 8 caractere.' });
  }

  // Verifică dacă apelantul este admin — decodare JWT locală (Render blochează googleapis.com)
  let callerIsAdmin = false;
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const token = authHeader.split('Bearer ')[1];
      const parts = token.split('.');
      if (parts.length === 3) {
        const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
        const padded = base64 + '='.repeat((4 - base64.length % 4) % 4);
        const payload = JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
        const now = Math.floor(Date.now() / 1000);
        if (payload.exp && payload.exp > now &&
            payload.iss === 'https://securetoken.google.com/e-patrimoniu' &&
            payload.aud === 'e-patrimoniu') {
          const uid = payload.uid || payload.sub;
          if (uid) {
            const { rows } = await pool.query('SELECT role FROM users WHERE uid = $1', [uid]);
            callerIsAdmin = rows.length > 0 && rows[0].role === 'administrator';
          }
        }
      }
    } catch (_) { /* token invalid sau neautentificat */ }
  }

  // Admin poate alege orice rol; non-admin primește automat 'extern'
  const effectiveRole = callerIsAdmin ? (role ?? 'extern') : 'extern';

  try {
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`.trim(),
    });

    await pool.query(
      `INSERT INTO users (uid, "firstName", "lastName", email, phone, role, status, departament)
       VALUES ($1, $2, $3, $4, $5, $6, 'activ', $7)`,
      [
        userRecord.uid,
        firstName.trim(),
        lastName.trim(),
        email.trim().toLowerCase(),
        (phone ?? '').trim(),
        effectiveRole,
        departament ?? null,
      ]
    );

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

// PUT /api/users/me — update own profile
router.put('/me', verifyToken, async (req, res) => {
  const { firstName, lastName, phone, departament } = req.body;
  if (!firstName || !lastName) {
    return res.status(400).json({ error: 'Prenume și nume sunt obligatorii.' });
  }
  try {
    const result = await pool.query(
      'UPDATE users SET "firstName" = $1, "lastName" = $2, phone = $3, departament = $4 WHERE uid = $5',
      [firstName.trim(), lastName.trim(), (phone ?? '').trim(), departament ?? null, req.uid]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Utilizator negăsit.' });
    await auth.updateUser(req.uid, { displayName: `${firstName.trim()} ${lastName.trim()}`.trim() });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'modificare', entitate: 'Utilizator', entitateId: req.uid,
      detalii: `Profil actualizat: ${firstName.trim()} ${lastName.trim()}`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /users/me:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/users/me — delete own account
router.delete('/me', verifyToken, async (req, res) => {
  const uid = req.uid;
  const userName = req.userName;
  try {
    await pool.query('DELETE FROM users WHERE uid = $1', [uid]);
    await auth.deleteUser(uid);
    await writeAuditLog({
      userId: uid, userName,
      actiune: 'stergere', entitate: 'Utilizator', entitateId: uid,
      detalii: `Cont șters de utilizator`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /users/me:', err);
    res.status(500).json({ error: 'Eroare la ștergerea contului.' });
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
    const result = await pool.query(
      'UPDATE users SET role = $1 WHERE uid = $2',
      [role, uid]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Utilizator negăsit.' });

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
    const result = await pool.query(
      'UPDATE users SET status = $1 WHERE uid = $2',
      [status, uid]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Utilizator negăsit.' });

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
