'use strict';

const express = require('express');
const { db } = require('../firebase');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

const VALID_STATUSES = ['activ','prelungit','reziliat','expirat','finalizat','anulat'];

router.get('/', verifyToken, async (req, res) => {
  try {
    let q = db.collection('contracts').orderBy('createdAt', 'desc');
    if (req.query.propertyId) q = q.where('propertyId', '==', req.query.propertyId);
    const snap = await q.get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, propertyDenumire, transactionId, numarContract,
          parteContractanta, dataInceput, dataFinal, valoare, valutaMoneda, note } = req.body;

  if (!propertyId || !numarContract || !parteContractanta || !dataInceput || !dataFinal || valoare == null) {
    return res.status(400).json({ error: 'Câmpuri obligatorii lipsă.' });
  }
  const start = new Date(dataInceput);
  const end   = new Date(dataFinal);
  if (isNaN(start) || isNaN(end) || end <= start) {
    return res.status(400).json({ error: 'Interval de date invalid.' });
  }
  if (typeof valoare !== 'number' || valoare < 0) {
    return res.status(400).json({ error: 'Valoarea contractului trebuie să fie un număr pozitiv.' });
  }

  try {
    const ref = await db.collection('contracts').add({
      propertyId, propertyDenumire: propertyDenumire ?? '',
      transactionId: transactionId ?? null,
      numarContract, parteContractanta,
      dataInceput: start, dataFinal: end,
      valoare, valutaMoneda: valutaMoneda ?? 'RON',
      status: 'activ',
      documentUrl: null,
      note: note ?? null,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.uid,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'Contract', entitateId: ref.id,
      detalii: `Contract creat: ${numarContract} cu ${parteContractanta}`,
    });

    res.status(201).json({ id: ref.id });
  } catch (err) {
    console.error('POST /contracts:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    await db.collection('contracts').doc(req.params.id).update({ status });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Contract', entitateId: req.params.id,
      detalii: `Status → ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
