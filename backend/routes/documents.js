'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const VALID_TYPES    = ['hcl','extrasCF','planCadastral','raportEvaluare',
                        'contract','procesVerbal','actAditional','documentPlata','altele'];
const VALID_STATUSES = ['neverificat','inVerificare','verificat','respins'];

const DOC_SELECT = `
  SELECT id,
         denumire, tip, status,
         file_url        AS "fileUrl",
         file_type       AS "fileType",
         file_size       AS "fileSize",
         property_id     AS "propertyId",
         transaction_id  AS "transactionId",
         contract_id     AS "contractId",
         auction_id      AS "auctionId",
         numar_document  AS "numarDocument",
         data_document   AS "dataDocument",
         emitent,
         note,
         uploaded_at     AS "uploadedAt",
         uploaded_by     AS "uploadedBy"
  FROM documents
`;

// GET /api/documents
// Query params optionale: propertyId, transactionId, contractId, auctionId, tip, status
router.get('/', verifyToken, async (req, res) => {
  try {
    const conditions = [];
    const params = [];

    if (req.query.propertyId) {
      params.push(req.query.propertyId);
      conditions.push(`property_id = $${params.length}`);
    }
    if (req.query.transactionId) {
      params.push(req.query.transactionId);
      conditions.push(`transaction_id = $${params.length}`);
    }
    if (req.query.contractId) {
      params.push(req.query.contractId);
      conditions.push(`contract_id = $${params.length}`);
    }
    if (req.query.auctionId) {
      params.push(req.query.auctionId);
      conditions.push(`auction_id = $${params.length}`);
    }
    if (req.query.tip) {
      params.push(req.query.tip);
      conditions.push(`tip = $${params.length}`);
    }
    if (req.query.status) {
      params.push(req.query.status);
      conditions.push(`status = $${params.length}`);
    }

    const where = conditions.length > 0 ? ' WHERE ' + conditions.join(' AND ') : '';
    const { rows } = await pool.query(DOC_SELECT + where + ' ORDER BY uploaded_at DESC', params);
    res.json(rows);
  } catch (err) {
    console.error('GET /documents:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/documents/:id
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      DOC_SELECT + ' WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Document negasit.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/documents
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const {
    denumire, tip,
    fileUrl, fileType, fileSize,
    propertyId, transactionId, contractId, auctionId,
    numarDocument, dataDocument, emitent, note,
  } = req.body;

  if (!denumire || !tip) {
    return res.status(400).json({ error: 'Campuri obligatorii: denumire, tip.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip document invalid: ${tip}` });
  }

  const dd = dataDocument ? new Date(dataDocument) : null;
  if (dataDocument && isNaN(dd)) {
    return res.status(400).json({ error: 'dataDocument invalida.' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO documents
         (denumire, tip, status,
          file_url, file_type, file_size,
          property_id, transaction_id, contract_id, auction_id,
          numar_document, data_document, emitent, note,
          uploaded_by)
       VALUES ($1,$2,'neverificat', $3,$4,$5, $6,$7,$8,$9, $10,$11,$12,$13, $14)
       RETURNING id`,
      [
        denumire, tip,
        fileUrl ?? '', fileType ?? 'pdf', Number(fileSize) || 0,
        propertyId ?? null, transactionId ?? null, contractId ?? null, auctionId ?? null,
        numarDocument ?? null, dd, emitent ?? null, note ?? null,
        req.uid,
      ]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'incarcarDocument', entitate: 'Document', entitateId: id,
      detalii: `Document adaugat: ${denumire} (${tip})`,
    });

    res.status(201).json({ id });
  } catch (err) {
    console.error('POST /documents:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/documents/:id/status
router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }
  try {
    const result = await pool.query(
      'UPDATE documents SET status = $1 WHERE id = $2',
      [status, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negasit.' });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Document', entitateId: req.params.id,
      detalii: `Status document -> ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/documents/:id
router.delete('/:id', verifyToken, requireAdminOrStaff, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM documents WHERE id = $1 RETURNING denumire',
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negasit.' });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'stergere', entitate: 'Document', entitateId: req.params.id,
      detalii: `Document sters: ${result.rows[0].denumire}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/documents/:id
router.delete('/:id', verifyToken, requireAdminOrStaff, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM documents WHERE id = $1 RETURNING denumire',
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negăsit.' });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'stergere', entitate: 'Document', entitateId: req.params.id,
      detalii: `Document șters: ${result.rows[0].denumire}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
