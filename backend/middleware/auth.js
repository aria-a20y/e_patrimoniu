'use strict';

const { auth, db } = require('../firebase');

/**
 * verifyToken — middleware
 * Verifies the Firebase ID token from `Authorization: Bearer <token>`,
 * fetches the user document from Firestore, and attaches:
 *   req.uid       — Firebase UID
 *   req.userRole  — 'administrator' | 'functionar' | 'extern'
 *   req.userName  — display name or email
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

    // Fetch role and status from Firestore (source of truth for RBAC)
    const userSnap = await db.collection('users').doc(decoded.uid).get();
    if (!userSnap.exists) {
      return res.status(403).json({ error: 'Utilizator negăsit în sistem.' });
    }

    const userData = userSnap.data();
    if (userData.status !== 'activ') {
      return res.status(403).json({ error: 'Contul este dezactivat sau suspendat.' });
    }

    req.userRole = userData.role;  // 'administrator' | 'functionar' | 'extern'
    req.userName = userData.firstName
      ? `${userData.firstName} ${userData.lastName}`.trim()
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
 * requireRole(...roles) — factory for role-guard middleware
 * Usage: router.post('/...', verifyToken, requireRole('administrator'), handler)
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

const requireAdmin         = requireRole('administrator');
const requireAdminOrStaff  = requireRole('administrator', 'functionar');

module.exports = { verifyToken, requireRole, requireAdmin, requireAdminOrStaff };
