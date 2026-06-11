'use strict';

const express = require('express');
const { db } = require('../firebase');
const { verifyToken, requireAdmin, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

const VALID_TYPES    = ['teren', 'cladire', 'spatiu', 'constructie'];
const VALID_DOMAINS  = ['public', 'privat'];
const VALID_STATUSES = ['activ', 'inactiv', 'scosEvidenta', 'inLitigiu'];

// GET /api/properties
router.get('/', verifyToken, async (req, res) => {
  try {
    let q = db.collection('properties').orderBy('createdAt', 'desc');
    if (req.query.tip) q = q.where('tip', '==', req.query.tip);
    const snap = await q.get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    console.error('GET /properties:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/properties/:id
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('properties').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Bun negăsit.' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/properties
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { denumire, tip, adresa, localitate, domeniuJuridic,
          numarCadastral, numarCarteF, suprafata, valoareInventar,
          destinatie, status, descriere } = req.body;

  // Input validation
  if (!denumire || !tip || !adresa || !localitate || !domeniuJuridic ||
      !numarCadastral || !numarCarteF || suprafata == null || valoareInventar == null || !destinatie) {
    return res.status(400).json({ error: 'Câmpuri obligatorii lipsă.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip invalid: ${tip}` });
  }
  if (!VALID_DOMAINS.includes(domeniuJuridic)) {
    return res.status(400).json({ error: `Domeniu juridic invalid: ${domeniuJuridic}` });
  }
  if (typeof suprafata !== 'number' || suprafata <= 0) {
    return res.status(400).json({ error: 'Suprafața trebuie să fie un număr pozitiv.' });
  }
  if (typeof valoareInventar !== 'number' || valoareInventar < 0) {
    return res.status(400).json({ error: 'Valoarea de inventar trebuie să fie un număr pozitiv.' });
  }

  try {
    const ref = await db.collection('properties').add({
      denumire, tip, adresa, localitate, domeniuJuridic,
      numarCadastral, numarCarteF,
      suprafata: Number(suprafata),
      valoareInventar: Number(valoareInventar),
      destinatie,
      status: VALID_STATUSES.includes(status) ? status : 'activ',
      descriere: descriere ?? null,
      imageUrl: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: req.uid,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'BunImobiliar', entitateId: ref.id,
      detalii: `Bun adăugat: ${denumire} (${tip})`,
    });

    res.status(201).json({ id: ref.id });
  } catch (err) {
    console.error('POST /properties:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/properties/:id
router.put('/:id', verifyToken, requireAdminOrStaff, async (req, res) => {
  const allowed = ['denumire', 'adresa', 'localitate', 'suprafata',
                   'valoareInventar', 'destinatie', 'status', 'descriere', 'imageUrl'];
  const updates = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) updates[key] = req.body[key];
  }
  updates.updatedAt = FieldValue.serverTimestamp();

  if (updates.status && !VALID_STATUSES.includes(updates.status)) {
    return res.status(400).json({ error: `Status invalid: ${updates.status}` });
  }

  try {
    const doc = await db.collection('properties').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Bun negăsit.' });

    await doc.ref.update(updates);
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'modificare', entitate: 'BunImobiliar', entitateId: req.params.id,
      detalii: `Bun actualizat: ${Object.keys(updates).filter(k => k !== 'updatedAt').join(', ')}`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /properties/:id:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/properties/:id — admin only (soft delete via status)
router.delete('/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const doc = await db.collection('properties').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Bun negăsit.' });

    await doc.ref.update({
      status: 'scosEvidenta',
      updatedAt: FieldValue.serverTimestamp(),
    });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'stergere', entitate: 'BunImobiliar', entitateId: req.params.id,
      detalii: `Bun scos din evidență`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
