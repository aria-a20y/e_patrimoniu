'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdmin, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const VALID_TYPES    = ['teren', 'cladire', 'spatiu', 'constructie'];
const VALID_DOMAINS  = ['public', 'privat'];
const VALID_STATUSES = ['activ', 'inactiv', 'scosEvidenta', 'inLitigiu'];

// GET /api/properties
router.get('/', verifyToken, async (req, res) => {
  try {
    let query = `
      SELECT id, denumire, tip, adresa, localitate, domeniu_juridic AS "domeniuJuridic",
             numar_cadastral AS "numarCadastral", numar_carte_f AS "numarCarteF",
             suprafata, valoare_inventar AS "valoareInventar", destinatie, status,
             descriere, image_url AS "imageUrl", created_at AS "createdAt",
             updated_at AS "updatedAt", created_by AS "createdBy"
      FROM properties
    `;
    const params = [];
    const conditions = [];
    if (req.query.tip) {
      params.push(req.query.tip);
      conditions.push(`tip = $${params.length}`);
    }
    if (req.query.localitate) {
      params.push(req.query.localitate);
      conditions.push(`localitate = $${params.length}`);
    }
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    query += ' ORDER BY created_at DESC';

    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error('GET /properties:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/properties/:id
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, denumire, tip, adresa, localitate, domeniu_juridic AS "domeniuJuridic",
              numar_cadastral AS "numarCadastral", numar_carte_f AS "numarCarteF",
              suprafata, valoare_inventar AS "valoareInventar", destinatie, status,
              descriere, image_url AS "imageUrl", created_at AS "createdAt",
              updated_at AS "updatedAt", created_by AS "createdBy"
       FROM properties WHERE id = $1`,
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Bun negăsit.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/properties
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { denumire, tip, adresa, localitate, domeniuJuridic,
          numarCadastral, numarCarteF, suprafata, valoareInventar,
          destinatie, status, descriere } = req.body;

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

  const effectiveStatus = VALID_STATUSES.includes(status) ? status : 'activ';

  try {
    const { rows } = await pool.query(
      `INSERT INTO properties
         (denumire, tip, adresa, localitate, domeniu_juridic, numar_cadastral, numar_carte_f,
          suprafata, valoare_inventar, destinatie, status, descriere, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING id`,
      [denumire, tip, adresa, localitate, domeniuJuridic, numarCadastral, numarCarteF,
       suprafata, valoareInventar, destinatie, effectiveStatus, descriere ?? null, req.uid]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'adaugare', entitate: 'BunImobiliar', entitateId: id,
      detalii: `Bun adăugat: ${denumire} (${tip})`,
    });

    res.status(201).json({ id });
  } catch (err) {
    console.error('POST /properties:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/properties/:id
router.put('/:id', verifyToken, requireAdminOrStaff, async (req, res) => {
  const allowed = ['denumire', 'adresa', 'localitate', 'suprafata',
                   'valoareInventar', 'destinatie', 'status', 'descriere', 'imageUrl'];

  // Map camelCase → snake_case pentru coloanele PostgreSQL
  const colMap = {
    denumire: 'denumire', adresa: 'adresa', localitate: 'localitate',
    suprafata: 'suprafata', valoareInventar: 'valoare_inventar',
    destinatie: 'destinatie', status: 'status', descriere: 'descriere',
    imageUrl: 'image_url',
  };

  const setClauses = [];
  const params = [];

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      if (key === 'status' && !VALID_STATUSES.includes(req.body[key])) {
        return res.status(400).json({ error: `Status invalid: ${req.body[key]}` });
      }
      params.push(req.body[key]);
      setClauses.push(`${colMap[key]} = $${params.length}`);
    }
  }

  if (setClauses.length === 0) {
    return res.status(400).json({ error: 'Niciun câmp de actualizat.' });
  }

  params.push(new Date()); // updated_at
  setClauses.push(`updated_at = $${params.length}`);
  params.push(req.params.id); // WHERE id

  try {
    const result = await pool.query(
      `UPDATE properties SET ${setClauses.join(', ')} WHERE id = $${params.length} RETURNING id`,
      params
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Bun negăsit.' });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'modificare', entitate: 'BunImobiliar', entitateId: req.params.id,
      detalii: `Bun actualizat: ${Object.keys(req.body).filter(k => allowed.includes(k)).join(', ')}`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /properties/:id:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/properties/:id — soft delete (status = scosEvidenta)
router.delete('/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE properties SET status = 'scosEvidenta', updated_at = NOW() WHERE id = $1`,
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Bun negăsit.' });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'stergere', entitate: 'BunImobiliar', entitateId: req.params.id,
      detalii: 'Bun scos din evidență',
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
