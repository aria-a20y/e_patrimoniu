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

  // Verifică dacă apelantul este admin
  let callerIsAdmin = false;
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const decoded = await auth.verifyIdToken(authHeader.split('Bearer ')[1], true);
      const { rows } = await pool.query(
        'SELECT role FROM users WHERE uid = $1',
        [decoded.uid]
      );
      callerIsAdmin = rows.length > 0 && rows[0].role === 'administrator';
    } catch (_) { /* token invalid sau neautentificat */ }
  }

  const effectiveRole = callerIsAdmin ? (role ?? 'extern') : 'extern';
  if (!callerIsAdmin && role && role !== 'extern') {
    return res.status(403).json({ error: 'Acces interzis: numai adminii pot crea conturi cu rol privilegiat.' });
  }

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
