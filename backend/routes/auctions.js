'use strict';

const express = require('express');
const { pool } = require('../db');
const { verifyToken, requireAdmin, requireAdminOrStaff } = require('../middleware/auth');
const { writeAuditLog } = require('../utils/audit');

const router = express.Router();

const AUCTION_SELECT = `
  SELECT id, property_id AS "propertyId", property_denumire AS "propertyDenumire",
         titlu, tip_atribuire AS "tipAtribuire",
         pret_pornire AS "pretPornire", pas_licitare AS "pasLicitare",
         garantie_participare AS "garantieParticipare",
         data_inceput AS "dataInceput", data_final AS "dataFinal",
         status, castigator_id AS "castigatorId", castigator_nume AS "castigatorNume",
         oferta_castigatoare AS "ofertaCastigatoare",
         transaction_id AS "transactionId", contract_id AS "contractId",
         descriere, created_at AS "createdAt", created_by AS "createdBy"
  FROM auctions
`;

// GET /api/auctions
router.get('/', verifyToken, async (req, res) => {
  try {
    let query = AUCTION_SELECT;
    const params = [];
    if (req.query.status) {
      params.push(req.query.status);
      query += ` WHERE status = $${params.length}`;
    }
    query += ' ORDER BY created_at DESC';
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error('GET /auctions:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      AUCTION_SELECT + ' WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Licitație negăsită.' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auctions
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
    return res.status(400).json({ error: 'Interval de date invalid.' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO auctions
         (property_id, property_denumire, titlu, tip_atribuire, pret_pornire, pas_licitare,
          garantie_participare, data_inceput, data_final, status, descriere, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'draft',$10,$11)
       RETURNING id`,
      [
        propertyId, propertyDenumire ?? '', titlu, tipAtribuire,
        Number(pretPornire), Number(pasLicitare), Number(garantieParticipare),
        start, end, descriere ?? null, req.uid,
      ]
    );

    const id = rows[0].id;
    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'creareLicitatie', entitate: 'Licitatie', entitateId: id,
      detalii: `Licitație creată: ${titlu}`,
    });

    res.status(201).json({ id });
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
    const result = await pool.query(
      'UPDATE auctions SET status = $1 WHERE id = $2',
      [status, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Licitație negăsită.' });

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
    const { rows: existing } = await pool.query(
      'SELECT status FROM auctions WHERE id = $1',
      [req.params.id]
    );
    if (existing.length === 0) return res.status(404).json({ error: 'Licitație negăsită.' });
    if (!['activa', 'inchisa'].includes(existing[0].status)) {
      return res.status(409).json({
        error: 'Câștigătorul poate fi desemnat doar pentru licitații active sau închise.',
      });
    }

    await pool.query(
      `UPDATE auctions
       SET status = 'atribuita', castigator_id = $1, castigator_nume = $2, oferta_castigatoare = $3
       WHERE id = $4`,
      [winnerId, winnerName, winningBid, req.params.id]
    );

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

// POST /api/auctions/:id/participants — înregistrare participare
router.post('/:id/participants', verifyToken, async (req, res) => {
  const auctionId = req.params.id;
  try {
    const { rows: aRows } = await pool.query(
      'SELECT status FROM auctions WHERE id = $1',
      [auctionId]
    );
    if (aRows.length === 0) return res.status(404).json({ error: 'Licitație negăsită.' });
    if (!['publicata', 'activa'].includes(aRows[0].status)) {
      return res.status(409).json({ error: 'Înregistrarea nu este posibilă pentru această licitație.' });
    }

    await pool.query(
      `INSERT INTO auction_participants (auction_id, user_id)
       VALUES ($1, $2) ON CONFLICT (auction_id, user_id) DO NOTHING`,
      [auctionId, req.uid]
    );

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'inregistrareParticipant', entitate: 'Licitatie', entitateId: auctionId,
      detalii: 'Participare înregistrată la licitație',
    });

    res.status(201).json({ success: true });
  } catch (err) {
    console.error('POST /auctions/:id/participants:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/participants/me — verifică dacă utilizatorul curent e înregistrat
router.get('/:id/participants/me', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id FROM auction_participants WHERE auction_id = $1 AND user_id = $2 LIMIT 1',
      [req.params.id, req.uid]
    );
    res.json({ registered: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/bids/me — verifică dacă utilizatorul curent a depus o ofertă
router.get('/:id/bids/me', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, valoare FROM bids WHERE auction_id = $1 AND participant_id = $2 LIMIT 1`,
      [req.params.id, req.uid]
    );
    res.json({ hasBid: rows.length > 0, bid: rows[0] || null });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/bids
router.get('/:id/bids', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, auction_id AS "auctionId", participant_id AS "participantId",
              participant_nume AS "participantNume", valoare,
              data_ora AS "dataOra", validata, respinsa, motiv_respingere AS "motivRespingere"
       FROM bids WHERE auction_id = $1 ORDER BY data_ora DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/auctions/:id/bids/:bidId/criteria — actualizare criterii (admin/staff)
router.put('/:id/bids/:bidId/criteria', verifyToken, requireAdminOrStaff, async (req, res) => {
  const { criteria } = req.body;
  if (!Array.isArray(criteria)) {
    return res.status(400).json({ error: 'criteria trebuie să fie un array.' });
  }
  try {
    for (const c of criteria) {
      if (c.criterionIndex < 1 || c.criterionIndex > 10) continue;
      await pool.query(`
        INSERT INTO bid_criteria (bid_id, criterion_index, is_met)
        VALUES ($1, $2, $3)
        ON CONFLICT (bid_id, criterion_index) DO UPDATE SET is_met = EXCLUDED.is_met
      `, [req.params.bidId, c.criterionIndex, Boolean(c.isMet)]);
    }
    res.json({ success: true });
  } catch (err) {
    console.error('PUT /auctions/:id/bids/:bidId/criteria:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auctions/:id/auto-winner — calculează și setează câștigătorul automat
router.post('/:id/auto-winner', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { rows: existing } = await pool.query(
      'SELECT status FROM auctions WHERE id = $1', [req.params.id]
    );
    if (existing.length === 0) return res.status(404).json({ error: 'Licitație negăsită.' });
    if (!['activa', 'inchisa'].includes(existing[0].status)) {
      return res.status(409).json({ error: 'Câștigătorul poate fi calculat doar pentru licitații active sau închise.' });
    }

    // Ofertantul cu cele mai multe criterii îndeplinite (≥7), tie-break: ofertă maximă
    const { rows: candidates } = await pool.query(`
      SELECT b.id, b.participant_id, b.participant_nume, b.valoare,
             COUNT(bc.criterion_index) FILTER (WHERE bc.is_met = TRUE) AS met_count
      FROM bids b
      LEFT JOIN bid_criteria bc ON bc.bid_id = b.id
      WHERE b.auction_id = $1 AND b.respinsa = FALSE
      GROUP BY b.id, b.participant_id, b.participant_nume, b.valoare
      HAVING COUNT(bc.criterion_index) FILTER (WHERE bc.is_met = TRUE) >= 7
      ORDER BY met_count DESC, b.valoare DESC
      LIMIT 1
    `, [req.params.id]);

    if (candidates.length === 0) {
      return res.status(422).json({
        error: 'Niciun ofertant nu îndeplinește minimum 7 criterii. Nu se poate desemna câștigătorul automat.',
      });
    }

    const w = candidates[0];
    await pool.query(
      `UPDATE auctions SET status = 'atribuita',
       castigator_id = $1, castigator_nume = $2, oferta_castigatoare = $3
       WHERE id = $4`,
      [w.participant_id, w.participant_nume, Number(w.valoare), req.params.id]
    );

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'actualizareStatus', entitate: 'Licitatie', entitateId: req.params.id,
      detalii: `Câștigător desemnat automat: ${w.participant_nume} — ${Number(w.valoare).toFixed(2)} RON (${w.met_count}/10 criterii)`,
    });

    res.json({ success: true, winner: { name: w.participant_nume, bid: Number(w.valoare), metCount: Number(w.met_count) } });
  } catch (err) {
    console.error('POST /auctions/:id/auto-winner:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auctions/:id/bids/:bidId/criteria — profilul criteriilor unui ofertant
router.get('/:id/bids/:bidId/criteria', verifyToken, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT criterion_index AS "criterionIndex", is_met AS "isMet"
       FROM bid_criteria
       WHERE bid_id = $1
       ORDER BY criterion_index`,
      [req.params.bidId]
    );
    res.json(rows);
  } catch (err) {
    console.error('GET /auctions/:id/bids/:bidId/criteria:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auctions/:id/bids
router.post('/:id/bids', verifyToken, async (req, res) => {
  const auctionId = req.params.id;
  const { valoare } = req.body;

  if (valoare == null || typeof valoare !== 'number' || valoare <= 0) {
    return res.status(400).json({ error: 'Valoarea ofertei trebuie să fie un număr pozitiv.' });
  }

  try {
    const { rows: aRows } = await pool.query(
      'SELECT status, pret_pornire, pas_licitare, data_inceput, data_final FROM auctions WHERE id = $1',
      [auctionId]
    );
    if (aRows.length === 0) return res.status(404).json({ error: 'Licitație negăsită.' });

    const auction = aRows[0];

    if (auction.status !== 'activa') {
      return res.status(409).json({ error: `Licitația nu este activă. Status: ${auction.status}` });
    }

    const now = new Date();
    if (now < new Date(auction.data_inceput) || now > new Date(auction.data_final)) {
      return res.status(409).json({ error: 'Nu sunteți în intervalul de depunere a ofertelor.' });
    }

    if (valoare < Number(auction.pret_pornire)) {
      return res.status(400).json({
        error: `Oferta (${valoare} RON) este sub prețul de pornire (${auction.pret_pornire} RON).`,
      });
    }

    const overshoot = (valoare - Number(auction.pret_pornire)) % Number(auction.pas_licitare);
    if (Math.abs(overshoot) > 0.01) {
      return res.status(400).json({
        error: `Oferta trebuie să respecte pasul de licitare de ${auction.pas_licitare} RON.`,
      });
    }

    // Verifică participantul înregistrat
    const { rows: pRows } = await pool.query(
      'SELECT id FROM auction_participants WHERE auction_id = $1 AND user_id = $2 LIMIT 1',
      [auctionId, req.uid]
    );
    if (pRows.length === 0) {
      return res.status(403).json({ error: 'Nu ești înregistrat ca participant la această licitație.' });
    }

    // Verifică dacă utilizatorul a mai depus o ofertă (o singură ofertă permisă per participant)
    const { rows: existingBid } = await pool.query(
      'SELECT id FROM bids WHERE auction_id = $1 AND participant_id = $2 LIMIT 1',
      [auctionId, req.uid]
    );
    if (existingBid.length > 0) {
      return res.status(409).json({ error: 'Ați depus deja o ofertă la această licitație. Fiecare participant poate depune o singură ofertă.' });
    }

    const { rows: bidRows } = await pool.query(
      `INSERT INTO bids (auction_id, participant_id, participant_nume, valoare)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [auctionId, req.uid, req.userName, valoare]
    );

    await writeAuditLog({
      userId: req.uid, userName: req.userName,
      actiune: 'depunereOferta', entitate: 'Licitatie', entitateId: auctionId,
      detalii: `Ofertă depusă: ${valoare.toFixed(2)} RON`,
    });

    res.status(201).json({ id: bidRows[0].id });
  } catch (err) {
    console.error('POST /auctions/:id/bids:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
