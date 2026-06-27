'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/audit — toti utilizatorii autentificati
router.get('/', verifyToken, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit ?? '200', 10), 500);
    const { rows } = await pool.query(
      `SELECT id, user_id AS "userId", user_name AS "userName",
              actiune, entitate, entitate_id AS "entitateId",
              detalii, timestamp
       FROM audit_log
       ORDER BY timestamp DESC
       LIMIT $1`,
      [limit]
    );
    res.json(rows);
  } catch (err) {
    console.error('GET /audit:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
