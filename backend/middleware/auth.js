'use strict';

const { pool } = require('../db');

/**
 * Decodifică și validează un Firebase JWT local (fără rețea).
 * Verifică: structura, exp, iat, iss, aud.
 * NU verifică semnătura RS256 (Render blochează googleapis.com).
 */
function decodeAndValidateJwt(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64 + '='.repeat((4 - base64.length % 4) % 4);
    const payload = JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
    const now = Math.floor(Date.now() / 1000);
    if (!payload.exp || payload.exp < now) return null;
    if (payload.iat && payload.iat > now + 300) return null;
    if (payload.iss !== 'https://securetoken.google.com/e-patrimoniu') return null;
    if (payload.aud !== 'e-patrimoniu') return null;
    return payload;
  } catch (_) { return null; }
}

/**
 * verifyToken — middleware
 * Verifică Firebase ID token din `Authorization: Bearer <token>`,
 * citește utilizatorul din PostgreSQL și atașează:
 *   req.uid       — Firebase UID
 *   req.userRole  — 'administrator' | 'functionar' | 'extern'
 *   req.userName  — nume complet sau email
 */
async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de autentificare lipsă.' });
  }
  const token = authHeader.split('Bearer ')[1];
  try {
    const payload = decodeAndValidateJwt(token);
    if (!payload) return res.status(401).json({ error: 'Token invalid.' });
    const uid = payload.uid || payload.sub;
    if (!uid) return res.status(401).json({ error: 'Token invalid.' });
    req.uid = uid;

    const { rows } = await pool.query(
      'SELECT "firstName", "lastName", email, role, status FROM users WHERE uid = $1',
      [uid]
    );

    if (rows.length === 0) {
      // Auto-creare user la primul login Firebase
      const { rows: countRows } = await pool.query('SELECT COUNT(*) FROM users');
      const isFirst = parseInt(countRows[0].count, 10) === 0;
      const role = isFirst ? 'administrator' : 'extern';
      const email = payload.email || '';
      const name = payload.name || '';
      const nameParts = name.trim().split(/\s+/);
      const firstName = nameParts[0] || email.split('@')[0] || 'Utilizator';
      const lastName = nameParts.slice(1).join(' ') || '';
      await pool.query(
        `INSERT INTO users (uid, "firstName", "lastName", email, role, status)
         VALUES ($1, $2, $3, $4, $5, 'activ')
         ON CONFLICT (uid) DO NOTHING`,
        [uid, firstName, lastName, email, role]
      );
      req.userRole = role;
      req.userName = name || email || uid;
      return next();
    }

    const user = rows[0];
    if (user.status !== 'activ') {
      return res.status(403).json({ error: 'Contul este dezactivat sau suspendat.' });
    }
    req.userRole = user.role;
    req.userName = user.firstName
      ? `${user.firstName} ${user.lastName}`.trim()
      : (payload.email ?? uid);
    next();
  } catch (err) {
    console.error('verifyToken error:', err.message);
    return res.status(500).json({ error: 'Eroare internă.' });
  }
}

/**
 * requireRole(...roles) — factory pentru middleware de guard pe rol
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.userRole)) {
      return res.status(403).json({
        error: `Acces interzis. Roluri permise: ${roles.join(', ')}.`,
      });
    }
    next();
  };
}

const requireAdmin        = requireRole('administrator');
const requireAdminOrStaff = requireRole('administrator', 'functionar');

module.exports = { verifyToken, requireRole, requireAdmin, requireAdminOrStaff };
