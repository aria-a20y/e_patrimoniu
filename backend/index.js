'use strict';

require('./firebase'); // Initialize Firebase Admin SDK before anything else

const express = require('express');
const helmet  = require('helmet');
const cors    = require('cors');

const usersRouter       = require('./routes/users');
const propertiesRouter  = require('./routes/properties');
const transactionsRouter = require('./routes/transactions');
const contractsRouter   = require('./routes/contracts');
const auctionsRouter    = require('./routes/auctions');
const documentsRouter   = require('./routes/documents');

const app  = express();
const PORT = process.env.PORT || 10000;

// ─── Security headers ────────────────────────────────────────────────────────
app.use(helmet());

// ─── CORS ────────────────────────────────────────────────────────────────────
// ALLOWED_ORIGIN is set in Render env vars to your Vercel URL, e.g.:
//   https://e-patrimoniu.vercel.app
// Multiple origins can be comma-separated: "https://a.vercel.app,http://localhost:5000"
const rawOrigins  = (process.env.ALLOWED_ORIGIN ?? 'http://localhost:5000').split(',').map(s => s.trim());
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (e.g. same-origin, curl, Render health checks)
    if (!origin || rawOrigins.includes(origin)) return callback(null, true);
    callback(new Error(`CORS: origin not allowed: ${origin}`));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ─── Body parser ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));

// ─── Routes ──────────────────────────────────────────────────────────────────
app.use('/api/users',        usersRouter);
app.use('/api/properties',   propertiesRouter);
app.use('/api/transactions', transactionsRouter);
app.use('/api/contracts',    contractsRouter);
app.use('/api/auctions',     auctionsRouter);
app.use('/api/documents',    documentsRouter);

// Health check — used by Render to confirm the service is alive
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'e-patrimoniu-api', timestamp: new Date().toISOString() });
});

// ─── 404 catch-all ───────────────────────────────────────────────────────────
app.use((_req, res) => res.status(404).json({ error: 'Endpoint negăsit.' }));

// ─── Global error handler ────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  // Never expose internal error details to the client
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Eroare internă server.' });
});

app.listen(PORT, () => {
  console.log(`e-Patrimoniu API listening on port ${PORT}`);
});
