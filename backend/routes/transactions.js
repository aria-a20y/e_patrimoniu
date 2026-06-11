'use strict';

const express = require('express');
const { db } = require('../firebase');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

const VALID_TYPES    = ['vanzare','cumparare','inchiriere','concesionare',
                        'dareAdministrare','dareFolosintaGratuita','comodat',
                        'schimbImobiliar','transfer','preluarePatrimoniu',
                        'scoatereEvidenta','modificareValoare'];
const VALID_STATUSES = ['initiata','aprobata','inDerulare','finalizata','anulata'];

router.get('/', verifyToken, async (req, res) => {
  try {
    let q = db.collection('transactions').orderBy('createdAt', 'desc');
    if (req.query.propertyId) q = q.where('propertyId', '==', req.query.propertyId);
    const snap = await q.get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, propertyDenumire, tip, descriere, numarHcl, dataTransactie, note } = req.body;

  if (!propertyId || !tip || !descriere || !numarHcl || !dataTransactie) {
    return res.status(400).json({ error: 'Câmpuri obligatorii lipsă.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip tranzacție invalid: ${tip}` });
  }

  try {
    const ref = await db.collection('transactions').add({
      propertyId, propertyDenumire: propertyDenumire ?? '',
      tip, descriere, numarHcl,
      dataTransactie: new Date(dataTransactie),
      status: 'initiata',
      documentIds: [],
      note: note ?? null,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.uid,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'Tranzactie', entitateId: ref.id,
      detalii: `Tranzacție creată: ${tip} pentru ${propertyDenumire ?? propertyId}`,
    });

    res.status(201).json({ id: ref.id });
  } catch (err) {
    console.error('POST /transactions:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    await db.collection('transactions').doc(req.params.id).update({ status });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Tranzactie', entitateId: req.params.id,
      detalii: `Status → ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
