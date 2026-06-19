'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const VALID_TYPES    = ['hcl','extrasCF','planCadastral','raportEvaluare',
                        'contract','procesVerbal','actAditional','documentPlata','altele'];
const VALID_STATUSES = ['neverificat','inVerificare','verificat','respins'];

// GET /api/documents
router.get('/', verifyToken, async (req, res) => {
  try {
    let query = `
      SELECT id, property_id AS "propertyId", denumire, tip, status,
             numar_document AS "numarDocument", data_document AS "dataDocument",
             emitent, descriere, file_url AS "fileUrl", file_type AS "fileType",
             file_size AS "fileSize", note, created_at AS "createdAt", created_by AS "createdBy"
      FROM documents
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

// POST /api/documents
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, denumire, tip, numarDocument, dataDocument, emitent, descriere,
          fileUrl, fileType, fileSize, note } = req.body;

  if (!denumire || !tip) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: denumire, tip.' });
  }
  if (!VALID_TYPES.includes(tip)) {
    return res.status(400).json({ error: `Tip document invalid: ${tip}` });
  }

  const dd = dataDocument ? new Date(dataDocument) : null;
  if (dataDocument && isNaN(dd)) {
    return res.status(400).json({ error: 'dataDocument invalidă.' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO documents
         (property_id, denumire, tip, status, numar_document, data_document, emitent, descriere,
          file_url, file_type, file_size, note, created_by)
       VALUES ($1,$2,$3,'neverificat',$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING id`,
      [propertyId ?? null, denumire, tip,
       numarDocument ?? null, dd, emitent ?? null, descriere ?? null,
       fileUrl ?? null, fileType ?? null, fileSize ?? null, note ?? null, req.uid]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'incarcarDocument', entitate: 'Document', entitateId: id,
      detalii: `Document adăugat: ${denumire}`,
    });

    res.status(201).json({ id });
  } catch (err) {
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
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negăsit.' });

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

// DELETE /api/documents/:id
router.delete('/:id', verifyToken, requireAdminOrStaff, async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM documents WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Document negăsit.' });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'stergereDocument', entitate: 'Document', entitateId: req.params.id,
      detalii: 'Document șters',
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
