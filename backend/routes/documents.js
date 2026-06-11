'use strict';

const express = require('express');
const { db } = require('../firebase');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

const VALID_TYPES    = ['hcl','extrasCF','planCadastral','raportEvaluare',
                        'contract','procesVerbal','actAditional','documentPlata','altele'];
const VALID_STATUSES = ['neverificat','inVerificare','verificat','respins'];

router.get('/', verifyToken, async (req, res) => {
  try {
    let q = db.collection('documents').orderBy('createdAt', 'desc');
    if (req.query.propertyId) q = q.where('propertyId', '==', req.query.propertyId);
    const snap = await q.get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, denumire, tip, numarDocument, dataDocument, emitent, descriere } = req.body;

  if (!propertyId || !denumire || !tip) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: propertyId, denumire, tip.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip document invalid: ${tip}` });
  }

  try {
    const ref = await db.collection('documents').add({
      propertyId, denumire, tip,
      status: 'neverificat',
      numarDocument: numarDocument ?? null,
      dataDocument: dataDocument ? new Date(dataDocument) : null,
      emitent: emitent ?? null,
      descriere: descriere ?? null,
      fileUrl: null, fileSize: null,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.uid,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'incarcarDocument', entitate: 'Document', entitateId: ref.id,
      detalii: `Document adăugat: ${denumire}`,
    });

    res.status(201).json({ id: ref.id });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    await db.collection('documents').doc(req.params.id).update({ status });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Document', entitateId: req.params.id,
      detalii: `Status document → ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
