'use strict';

const express = require('express');
const multer  = require('multer');
const { pool } = require('../db');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

// Multer — stocare în memorie (bytes → PostgreSQL BYTEA)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB
});

const VALID_TYPES    = ['hcl','extrasCF','planCadastral','raportEvaluare',
                        'contract','procesVerbal','actAditional','documentPlata','altele'];
const VALID_STATUSES = ['neverificat','inVerificare','verificat','respins'];

const CONTENT_TYPES = {
  pdf:  'application/pdf',
  jpg:  'image/jpeg',
  jpeg: 'image/jpeg',
  png:  'image/png',
  doc:  'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

const DOC_SELECT = `
  SELECT id,
         denumire, tip, status,
         file_type       AS "fileType",
         file_size::INTEGER AS "fileSize",
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

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/documents/upload — încarcă fișier binar (multipart/form-data)
// Stochează bytes direct în coloana file_data (BYTEA) din PostgreSQL.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/upload', verifyToken, requireAdminOrStaff,
  upload.single('file'),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: 'Niciun fișier trimis (câmp: file).' });
    }

    const { denumire, tip, propertyId, transactionId, contractId, auctionId,
            numarDocument, dataDocument, emitent, note } = req.body;

    const resolvedTip = VALID_TYPES.includes(tip) ? tip : 'altele';
    const ext = (req.file.originalname.split('.').pop() || 'bin').toLowerCase();
    const dd  = dataDocument ? new Date(dataDocument) : null;

    try {
      const { rows } = await pool.query(
        `INSERT INTO documents
           (denumire, tip, status,
            file_url, file_type, file_size, file_data,
            property_id, transaction_id, contract_id, auction_id,
            numar_document, data_document, emitent, note,
            uploaded_by)
         VALUES ($1,$2,'neverificat',
                 '', $3, $4, $5,
                 $6,$7,$8,$9,
                 $10,$11,$12,$13,
                 $14)
         RETURNING id`,
        [
          denumire || req.file.originalname,
          resolvedTip,
          ext,
          req.file.size,
          req.file.buffer,
          propertyId    ?? null,
          transactionId ?? null,
          contractId    ?? null,
          auctionId     ?? null,
          numarDocument ?? null,
          dd,
          emitent       ?? null,
          note          ?? null,
          req.uid,
        ]
      );

      const id = rows[0].id;
      await writeAuditLog({
        userId: req.uid, userName: req.userName,
        actiune: 'incarcarDocument', entitate: 'Document', entitateId: id,
        detalii: `Document încărcat: ${denumire || req.file.originalname} (${resolvedTip}, ${ext}, ${req.file.size} bytes)`,
      });

      res.status(201).json({ id });
    } catch (err) {
      console.error('POST /documents/upload:', err);
      res.status(500).json({ error: 'Eroare server la stocare fișier.' });
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/documents/:id/file — servește fișierul binar din PostgreSQL
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id/file', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT file_data, file_type, denumire FROM documents WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0 || !rows[0].file_data) {
      return res.status(404).json({ error: 'Fișier negăsit în baza de date.' });
    }

    const { file_data, file_type, denumire } = rows[0];
    const contentType = CONTENT_TYPES[file_type] || 'application/octet-stream';

    res.set('Content-Type', contentType);
    res.set('Content-Disposition', `inline; filename="${encodeURIComponent(denumire)}"`);
    res.set('Cache-Control', 'private, max-age=3600');
    res.send(file_data);
  } catch (err) {
    console.error('GET /documents/:id/file:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/documents — listă documente (fără file_data!)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', verifyToken, async (req, res) => {
  try {
    const conditions = [];
    const params = [];

    if (req.query.propertyId)    { params.push(req.query.propertyId);    conditions.push(`property_id = $${params.length}`); }
    if (req.query.transactionId) { params.push(req.query.transactionId); conditions.push(`transaction_id = $${params.length}`); }
    if (req.query.contractId)    { params.push(req.query.contractId);    conditions.push(`contract_id = $${params.length}`); }
    if (req.query.auctionId)     { params.push(req.query.auctionId);     conditions.push(`auction_id = $${params.length}`); }
    if (req.query.tip)           { params.push(req.query.tip);           conditions.push(`tip = $${params.length}`); }
    if (req.query.status)        { params.push(req.query.status);        conditions.push(`status = $${params.length}`); }

    const where = conditions.length > 0 ? ' WHERE ' + conditions.join(' AND ') : '';
    const { rows } = await pool.query(DOC_SELECT + where + ' ORDER BY uploaded_at DESC', params);
    res.json(rows);
  } catch (err) {
    console.error('GET /documents:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/documents/:id — detaliu document (fără file_data!)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(DOC_SELECT + ' WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Document negăsit.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/documents/:id/status
// ─────────────────────────────────────────────────────────────────────────────
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
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negăsit.' });
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

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/documents/:id — șterge metadate + fișier binar din PostgreSQL
// ─────────────────────────────────────────────────────────────────────────────
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
