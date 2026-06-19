'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const VALID_STATUSES = ['activ','prelungit','reziliat','expirat','finalizat','anulat'];

// GET /api/contracts
router.get('/', verifyToken, async (req, res) => {
  try {
    let query = `
      SELECT id, property_id AS "propertyId", property_denumire AS "propertyDenumire",
             transaction_id AS "transactionId", numar_contract AS "numarContract",
             parte_contractanta AS "parteContractanta",
             data_inceput AS "dataInceput", data_final AS "dataFinal",
             valoare, valuta_moneda AS "valutaMoneda", status,
             document_url AS "documentUrl", note,
             created_at AS "createdAt", created_by AS "createdBy"
      FROM contracts
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

// POST /api/contracts
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
    const { rows } = await pool.query(
      `INSERT INTO contracts
         (property_id, property_denumire, transaction_id, numar_contract, parte_contractanta,
          data_inceput, data_final, valoare, valuta_moneda, status, note, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'activ',$10,$11)
       RETURNING id`,
      [
        propertyId, propertyDenumire ?? '', transactionId ?? null,
        numarContract, parteContractanta, start, end,
        valoare, valutaMoneda ?? 'RON', note ?? null, req.uid,
      ]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'Contract', entitateId: id,
      detalii: `Contract creat: ${numarContract} cu ${parteContractanta}`,
    });

    res.status(201).json({ id });
  } catch (err) {
    console.error('POST /contracts:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/contracts/:id/status
router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    const result = await pool.query(
      'UPDATE contracts SET status = $1 WHERE id = $2',
      [status, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Contract negăsit.' });

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
