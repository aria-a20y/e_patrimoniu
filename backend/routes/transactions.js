'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const VALID_TYPES    = ['vanzare','cumparare','inchiriere','concesionare',
                        'dareAdministrare','dareFolosintaGratuita','comodat',
                        'schimbImobiliar','transfer','preluarePatrimoniu',
                        'scoatereEvidenta','modificareValoare'];
const VALID_STATUSES = ['initiata','aprobata','inDerulare','finalizata','anulata'];

// GET /api/transactions
router.get('/', verifyToken, async (req, res) => {
  try {
    let query = `
      SELECT id, property_id AS "propertyId", property_denumire AS "propertyDenumire",
             tip, descriere, numar_hcl AS "numarHcl", data_tranzactie AS "dataTransactie",
             status, note, created_at AS "createdAt", created_by AS "createdBy"
      FROM transactions
    `;
    const params = [];
    if (req.query.propertyId) {
      params.push(req.query.propertyId);
      query += ` WHERE property_id = $${params.length}`;
    }
    query += ' ORDER BY created_at DESC';

    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/transactions
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, propertyDenumire, tip, descriere, numarHcl, dataTransactie, note } = req.body;

  if (!propertyId || !tip || !descriere || !numarHcl || !dataTransactie) {
    return res.status(400).json({ error: 'Câmpuri obligatorii lipsă.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip tranzacție invalid: ${tip}` });
  }

  const dt = new Date(dataTransactie);
  if (isNaN(dt)) {
    return res.status(400).json({ error: 'dataTransactie invalidă.' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO transactions
         (property_id, property_denumire, tip, descriere, numar_hcl, data_tranzactie, status, note, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,'initiata',$7,$8)
       RETURNING id`,
      [propertyId, propertyDenumire ?? '', tip, descriere, numarHcl, dt, note ?? null, req.uid]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'Tranzactie', entitateId: id,
      detalii: `Tranzacție creată: ${tip} pentru ${propertyDenumire ?? propertyId}`,
    });

    res.status(201).json({ id });
  } catch (err) {
    console.error('POST /transactions:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/transactions/:id/status
router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    const result = await pool.query(
      'UPDATE transactions SET status = $1 WHERE id = $2',
      [status, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Tranzacție negăsită.' });

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
