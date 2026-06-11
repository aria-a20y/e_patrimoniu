'use strict';

const express = require('express');
const { db } = require('../firebase');
const { verifyToken, requireAdmin, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');
const { FieldValue } = require('firebase-admin/firestore');

const router = express.Router();

// GET /api/auctions
router.get('/', verifyToken, async (req, res) => {
  try {
    let q = db.collection('auctions').orderBy('createdAt', 'desc');
    if (req.query.status) q = q.where('status', '==', req.query.status);
    const snap = await q.get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    console.error('GET /auctions:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('auctions').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Licitație negăsită.' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auctions — admin sau funcționar
router.post('/', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { propertyId, propertyDenumire, titlu, tipAtribuire,
          pretPornire, pasLicitare, garantieParticipare,
          dataInceput, dataFinal, descriere } = req.body;

  if (!propertyId || !titlu || !tipAtribuire || pretPornire == null ||
      pasLicitare == null || garantieParticipare == null || !dataInceput || !dataFinal) {
    return res.status(400).json({ error: 'Câmpuri obligatorii lipsă.' });
  }
  if (!['vanzare', 'inchiriere', 'concesionare'].includes(tipAtribuire)) {
    return res.status(400).json({ error: 'tipAtribuire invalid.' });
  }
  if (Number(pretPornire) <= 0 || Number(pasLicitare) <= 0 || Number(garantieParticipare) < 0) {
    return res.status(400).json({ error: 'Valorile financiare trebuie să fie pozitive.' });
  }
  const start = new Date(dataInceput);
  const end   = new Date(dataFinal);
  if (isNaN(start) || isNaN(end) || end <= start) {
    return res.status(400).json({ error: 'Interval de date invalid (dataFinal trebuie să fie după dataInceput).' });
  }

  try {
    const ref = await db.collection('auctions').add({
      propertyId, propertyDenumire: propertyDenumire ?? '',
      titlu, tipAtribuire,
      pretPornire: Number(pretPornire),
      pasLicitare: Number(pasLicitare),
      garantieParticipare: Number(garantieParticipare),
      dataInceput: start,
      dataFinal: end,
      status: 'draft',
      castigatorId: null, castigatorNume: null, ofertaCastigatoare: null,
      transactionId: null, contractId: null,
      descriere: descriere ?? null,
      documentIds: [],
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.uid,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'creareLicitatie', entitate: 'Licitatie', entitateId: ref.id,
      detalii: `Licitație creată: ${titlu}`,
    });

    res.status(201).json({ id: ref.id });
  } catch (err) {
    console.error('POST /auctions:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/auctions/:id/status
router.put('/:id/status', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { status } = req.body;
  const VALID = ['draft', 'publicata', 'activa', 'inchisa', 'anulata', 'contestata'];

  if (!VALID.includes(status)) {
    return res.status(400).json({ error: `Status invalid: ${status}` });
  }

  try {
    const doc = await db.collection('auctions').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Licitație negăsită.' });

    await doc.ref.update({ status });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Licitatie', entitateId: req.params.id,
      detalii: `Status actualizat → ${status}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/auctions/:id/winner — admin only
router.put('/:id/winner', verifyToken, requireAdmin, async (req, res) => {
  const { winnerId, winnerName, winningBid } = req.body;

  if (!winnerId || !winnerName || winningBid == null) {
    return res.status(400).json({ error: 'Câmpuri obligatorii: winnerId, winnerName, winningBid.' });
  }
  if (typeof winningBid !== 'number' || winningBid <= 0) {
    return res.status(400).json({ error: 'winningBid trebuie să fie un număr pozitiv.' });
  }

  try {
    const doc = await db.collection('auctions').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Licitație negăsită.' });
    if (!['activa', 'inchisa'].includes(doc.data().status)) {
      return res.status(409).json({ error: 'Câștigătorul poate fi desemnat doar pentru licitații active sau închise.' });
    }

    await doc.ref.update({
      status: 'atribuita',
      castigatorId: winnerId,
      castigatorNume: winnerName,
      ofertaCastigatoare: winningBid,
    });
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Licitatie', entitateId: req.params.id,
      detalii: `Câștigător desemnat: ${winnerName} — ${winningBid.toFixed(2)} RON`,
    });
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /auctions/:id/winner:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/bids
router.get('/:id/bids', verifyToken, async (req, res) => {
  try {
    const snap = await db.collection('bids')
      .where('auctionId', '==', req.params.id)
      .orderBy('dataOra', 'desc')
      .get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auctions/:id/bids — F-07 fix: full business rule validation
router.post('/:id/bids', verifyToken, async (req, res) => {
  const auctionId = req.params.id;
  const { valoare } = req.body;

  if (valoare == null || typeof valoare !== 'number' || valoare <= 0) {
    return res.status(400).json({ error: 'Valoarea ofertei trebuie să fie un număr pozitiv.' });
  }

  try {
    const auctionSnap = await db.collection('auctions').doc(auctionId).get();
    if (!auctionSnap.exists) {
      return res.status(404).json({ error: 'Licitație negăsită.' });
    }
    const auction = auctionSnap.data();

    // Validate auction is active
    if (auction.status !== 'activa') {
      return res.status(409).json({ error: `Licitația nu este activă. Status: ${auction.status}` });
    }

    // Validate auction window
    const now = new Date();
    if (now < auction.dataInceput.toDate() || now > auction.dataFinal.toDate()) {
      return res.status(409).json({ error: 'Nu sunteți în intervalul de depunere a ofertelor.' });
    }

    // Validate minimum price
    if (valoare < auction.pretPornire) {
      return res.status(400).json({
        error: `Oferta (${valoare} RON) este sub prețul de pornire (${auction.pretPornire} RON).`,
      });
    }

    // Validate bid increment
    const overshoot = (valoare - auction.pretPornire) % auction.pasLicitare;
    if (Math.abs(overshoot) > 0.01) {
      return res.status(400).json({
        error: `Oferta trebuie să respecte pasul de licitare de ${auction.pasLicitare} RON.`,
      });
    }

    // Verify caller is registered participant
    const partSnap = await db.collection('auction_participants')
      .where('auctionId', '==', auctionId)
      .where('userId', '==', req.uid)
      .limit(1)
      .get();
    if (partSnap.empty) {
      return res.status(403).json({ error: 'Nu ești înregistrat ca participant la această licitație.' });
    }

    // Write bid with server-side timestamp and verified participantId
    const bidRef = await db.collection('bids').add({
      auctionId,
      participantId: req.uid,        // always from verified token, never from body
      participantNume: req.userName,
      valoare,
      dataOra: FieldValue.serverTimestamp(),
      validata: false,
      respinsa: false,
      motivRespingere: null,
    });

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'depunereOferta', entitate: 'Licitatie', entitateId: auctionId,
      detalii: `Ofertă depusă: ${valoare.toFixed(2)} RON`,
    });

    res.status(201).json({ id: bidRef.id });
  } catch (err) {
    console.error('POST /auctions/:id/bids:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
