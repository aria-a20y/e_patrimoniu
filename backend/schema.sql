-- ============================================================
-- e-Patrimoniu — PostgreSQL Schema
-- Rulează o singură dată după crearea bazei de date pe Render.
-- ============================================================

-- Extensie pentru UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── USERS ───────────────────────────────────────────────────
-- uid = Firebase Auth UID (string), PK
CREATE TABLE IF NOT EXISTS users (
  uid            TEXT        PRIMARY KEY,
  "firstName"    TEXT        NOT NULL,
  "lastName"     TEXT        NOT NULL,
  email          TEXT        NOT NULL UNIQUE,
  phone          TEXT        DEFAULT '',
  role           TEXT        NOT NULL DEFAULT 'extern'
                             CHECK (role IN ('administrator','functionar','extern')),
  status         TEXT        NOT NULL DEFAULT 'activ'
                             CHECK (status IN ('activ','inactiv','suspendat')),
  departament    TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── PROPERTIES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS properties (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  denumire           TEXT        NOT NULL,
  tip                TEXT        NOT NULL
                                 CHECK (tip IN ('teren','cladire','spatiu','constructie')),
  adresa             TEXT        NOT NULL,
  localitate         TEXT        NOT NULL,
  domeniu_juridic    TEXT        NOT NULL
                                 CHECK (domeniu_juridic IN ('public','privat')),
  numar_cadastral    TEXT        NOT NULL,
  numar_carte_f      TEXT        NOT NULL,
  suprafata          NUMERIC     NOT NULL CHECK (suprafata > 0),
  valoare_inventar   NUMERIC     NOT NULL CHECK (valoare_inventar >= 0),
  destinatie         TEXT        NOT NULL,
  status             TEXT        NOT NULL DEFAULT 'activ'
                                 CHECK (status IN ('activ','inactiv','scosEvidenta','inLitigiu')),
  descriere          TEXT,
  image_url          TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by         TEXT        REFERENCES users(uid) ON DELETE SET NULL
);

-- ─── TRANSACTIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id         UUID        NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  property_denumire   TEXT        NOT NULL DEFAULT '',
  tip                 TEXT        NOT NULL
                                  CHECK (tip IN (
                                    'vanzare','cumparare','inchiriere','concesionare',
                                    'dareAdministrare','dareFolosintaGratuita','comodat',
                                    'schimbImobiliar','transfer','preluarePatrimoniu',
                                    'scoatereEvidenta','modificareValoare'
                                  )),
  descriere           TEXT        NOT NULL,
  numar_hcl           TEXT        NOT NULL,
  data_tranzactie     DATE        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'initiata'
                                  CHECK (status IN ('initiata','aprobata','inDerulare','finalizata','anulata')),
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by          TEXT        REFERENCES users(uid) ON DELETE SET NULL
);

-- ─── CONTRACTS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contracts (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id         UUID        NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  property_denumire   TEXT        NOT NULL DEFAULT '',
  transaction_id      UUID        REFERENCES transactions(id) ON DELETE SET NULL,
  numar_contract      TEXT        NOT NULL,
  parte_contractanta  TEXT        NOT NULL,
  data_inceput        DATE        NOT NULL,
  data_final          DATE        NOT NULL,
  valoare             NUMERIC     NOT NULL CHECK (valoare >= 0),
  valuta_moneda       TEXT        NOT NULL DEFAULT 'RON',
  status              TEXT        NOT NULL DEFAULT 'activ'
                                  CHECK (status IN ('activ','prelungit','reziliat','expirat','finalizat','anulat')),
  document_url        TEXT,
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by          TEXT        REFERENCES users(uid) ON DELETE SET NULL,
  CONSTRAINT contracts_dates_check CHECK (data_final > data_inceput)
);

-- ─── AUCTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auctions (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id           UUID        NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  property_denumire     TEXT        NOT NULL DEFAULT '',
  titlu                 TEXT        NOT NULL,
  tip_atribuire         TEXT        NOT NULL
                                    CHECK (tip_atribuire IN ('vanzare','inchiriere','concesionare')),
  pret_pornire          NUMERIC     NOT NULL CHECK (pret_pornire > 0),
  pas_licitare          NUMERIC     NOT NULL CHECK (pas_licitare > 0),
  garantie_participare  NUMERIC     NOT NULL CHECK (garantie_participare >= 0),
  data_inceput          TIMESTAMPTZ NOT NULL,
  data_final            TIMESTAMPTZ NOT NULL,
  status                TEXT        NOT NULL DEFAULT 'draft'
                                    CHECK (status IN ('draft','publicata','activa','inchisa','anulata','contestata','atribuita')),
  castigator_id         TEXT,
  castigator_nume       TEXT,
  oferta_castigatoare   NUMERIC,
  transaction_id        UUID        REFERENCES transactions(id) ON DELETE SET NULL,
  contract_id           UUID        REFERENCES contracts(id) ON DELETE SET NULL,
  descriere             TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by            TEXT        REFERENCES users(uid) ON DELETE SET NULL,
  CONSTRAINT auctions_dates_check CHECK (data_final > data_inceput)
);

-- ─── BIDS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bids (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id          UUID        NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  participant_id      TEXT        NOT NULL,
  participant_nume    TEXT        NOT NULL,
  valoare             NUMERIC     NOT NULL CHECK (valoare > 0),
  data_ora            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  validata            BOOLEAN     NOT NULL DEFAULT FALSE,
  respinsa            BOOLEAN     NOT NULL DEFAULT FALSE,
  motiv_respingere    TEXT
);

-- ─── AUCTION PARTICIPANTS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS auction_participants (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id      UUID        NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id         TEXT        NOT NULL,
  registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (auction_id, user_id)
);

-- ─── DOCUMENTS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documents (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id       UUID        REFERENCES properties(id) ON DELETE CASCADE,
  denumire          TEXT        NOT NULL,
  tip               TEXT        NOT NULL
                                CHECK (tip IN (
                                  'hcl','extrasCF','planCadastral','raportEvaluare',
                                  'contract','procesVerbal','actAditional','documentPlata','altele'
                                )),
  status            TEXT        NOT NULL DEFAULT 'neverificat'
                                CHECK (status IN ('neverificat','inVerificare','verificat','respins')),
  numar_document    TEXT,
  data_document     DATE,
  emitent           TEXT,
  descriere         TEXT,
  file_url          TEXT,
  file_type         TEXT,
  file_size         BIGINT,
  note              TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by        TEXT        REFERENCES users(uid) ON DELETE SET NULL
);

-- ─── AUDIT LOG ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT        NOT NULL,
  user_name     TEXT        NOT NULL,
  actiune       TEXT        NOT NULL,
  entitate      TEXT        NOT NULL,
  entitate_id   TEXT,
  detalii       TEXT,
  timestamp     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── INDECȘI ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_properties_tip        ON properties(tip);
CREATE INDEX IF NOT EXISTS idx_properties_status     ON properties(status);
CREATE INDEX IF NOT EXISTS idx_transactions_prop     ON transactions(property_id);
CREATE INDEX IF NOT EXISTS idx_contracts_prop        ON contracts(property_id);
CREATE INDEX IF NOT EXISTS idx_auctions_prop         ON auctions(property_id);
CREATE INDEX IF NOT EXISTS idx_auctions_status       ON auctions(status);
CREATE INDEX IF NOT EXISTS idx_bids_auction          ON bids(auction_id);
CREATE INDEX IF NOT EXISTS idx_documents_prop        ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp   ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_user        ON audit_log(user_id);
