'use strict';

const { auth } = require('../firebase');
const { pool } = require('../db');

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
    const decoded = await auth.verifyIdToken(token, true /* checkRevoked */);
    req.uid = decoded.uid;

    // Citește rolul și statusul din PostgreSQL (sursa de adevăr pentru RBAC)
    const { rows } = await pool.query(
      'SELECT "firstName", "lastName", email, role, status FROM users WHERE uid = $1',
      [decoded.uid]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: 'Utilizator negăsit în sistem.' });
    }

    const user = rows[0];

    if (user.status !== 'activ') {
      return res.status(403).json({ error: 'Contul este dezactivat sau suspendat.' });
    }

    req.userRole = user.role;
    req.userName = user.firstName
      ? `${user.firstName} ${user.lastName}`.trim()
      : (decoded.email ?? decoded.uid);

    next();
  } catch (err) {
    if (err.code === 'auth/id-token-revoked') {
      return res.status(401).json({ error: 'Sesiunea a fost revocată. Reconectați-vă.' });
    }
    if (err.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Sesiunea a expirat. Reconectați-vă.' });
    }
    console.error('verifyToken error:', err.code, err.message);
    return res.status(401).json({ error: 'Token invalid.' });
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
