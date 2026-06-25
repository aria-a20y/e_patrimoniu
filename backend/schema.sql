-- ============================================================
-- e-Patrimoniu -- PostgreSQL Schema (completa)
-- Toate comenzile folosesc IF NOT EXISTS -- sigur de apelat
-- de mai multe ori (idempotent).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- USERS
-- uid = Firebase Auth UID (string), PK
CREATE TABLE IF NOT EXISTS users (
  uid            TEXT        PRIMARY KEY,
  "firstName"    TEXT        NOT NULL,
  "lastName"     TEXT        NOT NULL,
  email          TEXT        NOT NULL UNIQUE,
  phone          TEXT        NOT NULL DEFAULT '',
  role           TEXT        NOT NULL DEFAULT 'extern'
                             CHECK (role IN ('administrator','functionar','extern')),
  status         TEXT        NOT NULL DEFAULT 'activ'
                             CHECK (status IN ('activ','inactiv','suspendat')),
  departament    TEXT,
  photo_url      TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PROPERTIES -- bunuri imobiliare
CREATE TABLE IF NOT EXISTS properties (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  denumire           TEXT        NOT NULL,
  tip                TEXT        NOT NULL
                                 CHECK (tip IN ('teren','cladire','spatiu','constructie')),
  adresa             TEXT        NOT NULL,
  localitate         TEXT        NOT NULL,
  domeniu_juridic    TEXT        NOT NULL
                                 CHECK (domeniu_juridic IN ('public','privat')),
  numar_cadastral    TEXT        NOT NULL DEFAULT '',
  numar_carte_f      TEXT        NOT NULL DEFAULT '',
  suprafata          NUMERIC(15,4) NOT NULL CHECK (suprafata > 0),
  valoare_inventar   NUMERIC(15,2) NOT NULL CHECK (valoare_inventar >= 0),
  destinatie         TEXT        NOT NULL,
  status             TEXT        NOT NULL DEFAULT 'activ'
                                 CHECK (status IN ('activ','inactiv','scosEvidenta','inLitigiu')),
  descriere          TEXT,
  image_url          TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by         TEXT        REFERENCES users(uid) ON DELETE SET NULL
);

-- TRANSACTIONS -- tranzactii imobiliare
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
  numar_hcl           TEXT        NOT NULL DEFAULT '',
  data_tranzactie     DATE        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'initiata'
                                  CHECK (status IN ('initiata','aprobata','inDerulare','finalizata','anulata')),
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by          TEXT        REFERENCES users(uid) ON DELETE SET NULL
);

-- CONTRACTS -- contracte (inchiriere, concesionare etc.)
CREATE TABLE IF NOT EXISTS contracts (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id         UUID        NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  property_denumire   TEXT        NOT NULL DEFAULT '',
  transaction_id      UUID        REFERENCES transactions(id) ON DELETE SET NULL,
  numar_contract      TEXT        NOT NULL,
  parte_contractanta  TEXT        NOT NULL,
  data_inceput        DATE        NOT NULL,
  data_final          DATE        NOT NULL,
  valoare             NUMERIC(15,2) NOT NULL CHECK (valoare >= 0),
  valuta_moneda       TEXT        NOT NULL DEFAULT 'RON',
  status              TEXT        NOT NULL DEFAULT 'activ'
                                  CHECK (status IN ('activ','prelungit','reziliat','expirat','finalizat','anulat')),
  document_url        TEXT,
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by          TEXT        REFERENCES users(uid) ON DELETE SET NULL,
  CONSTRAINT contracts_dates_check CHECK (data_final > data_inceput)
);

-- AUCTIONS -- licitatii
CREATE TABLE IF NOT EXISTS auctions (
  id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id           UUID          NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  property_denumire     TEXT          NOT NULL DEFAULT '',
  titlu                 TEXT          NOT NULL,
  tip_atribuire         TEXT          NOT NULL
                                      CHECK (tip_atribuire IN ('vanzare','inchiriere','concesionare')),
  pret_pornire          NUMERIC(15,2) NOT NULL CHECK (pret_pornire > 0),
  pas_licitare          NUMERIC(15,2) NOT NULL CHECK (pas_licitare > 0),
  garantie_participare  NUMERIC(15,2) NOT NULL CHECK (garantie_participare >= 0),
  data_inceput          TIMESTAMPTZ   NOT NULL,
  data_final            TIMESTAMPTZ   NOT NULL,
  status                TEXT          NOT NULL DEFAULT 'draft'
                                      CHECK (status IN ('draft','publicata','activa','inchisa','atribuita','anulata','contestata')),
  castigator_id         TEXT,
  castigator_nume       TEXT,
  oferta_castigatoare   NUMERIC(15,2),
  transaction_id        UUID          REFERENCES transactions(id) ON DELETE SET NULL,
  contract_id           UUID          REFERENCES contracts(id) ON DELETE SET NULL,
  descriere             TEXT,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  created_by            TEXT          REFERENCES users(uid) ON DELETE SET NULL,
  CONSTRAINT auctions_dates_check CHECK (data_final > data_inceput)
);

-- BIDS -- oferte licitatie
CREATE TABLE IF NOT EXISTS bids (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id          UUID          NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  participant_id      TEXT          NOT NULL,
  participant_nume    TEXT          NOT NULL,
  valoare             NUMERIC(15,2) NOT NULL CHECK (valoare > 0),
  data_ora            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  validata            BOOLEAN       NOT NULL DEFAULT FALSE,
  respinsa            BOOLEAN       NOT NULL DEFAULT FALSE,
  motiv_respingere    TEXT
);

-- AUCTION PARTICIPANTS -- participanti inregistrati la licitatie
CREATE TABLE IF NOT EXISTS auction_participants (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id      UUID        NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id         TEXT        NOT NULL,
  registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (auction_id, user_id)
);

-- DOCUMENTS -- documente atasate (Firebase Storage URLs)
-- Poate fi legat de: proprietate, tranzactie, contract, licitatie
CREATE TABLE IF NOT EXISTS documents (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  denumire          TEXT          NOT NULL,
  tip               TEXT          NOT NULL
                                  CHECK (tip IN (
                                    'hcl','extrasCF','planCadastral','raportEvaluare',
                                    'contract','procesVerbal','actAditional','documentPlata','altele'
                                  )),
  status            TEXT          NOT NULL DEFAULT 'neverificat'
                                  CHECK (status IN ('neverificat','inVerificare','verificat','respins')),
  file_url          TEXT          NOT NULL DEFAULT '',
  file_type         TEXT          NOT NULL DEFAULT 'pdf',
  file_size         BIGINT        NOT NULL DEFAULT 0,
  property_id       UUID          REFERENCES properties(id) ON DELETE SET NULL,
  transaction_id    UUID          REFERENCES transactions(id) ON DELETE SET NULL,
  contract_id       UUID          REFERENCES contracts(id) ON DELETE SET NULL,
  auction_id        UUID          REFERENCES auctions(id) ON DELETE SET NULL,
  numar_document    TEXT,
  data_document     DATE,
  emitent           TEXT,
  note              TEXT,
  uploaded_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  uploaded_by       TEXT          REFERENCES users(uid) ON DELETE SET NULL
);

-- BID CRITERIA -- criterii de evaluare per ofertant (10 criterii, minim 7 = acceptat)
CREATE TABLE IF NOT EXISTS bid_criteria (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  bid_id          UUID    NOT NULL REFERENCES bids(id) ON DELETE CASCADE,
  criterion_index INTEGER NOT NULL CHECK (criterion_index BETWEEN 1 AND 10),
  is_met          BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (bid_id, criterion_index)
);

-- AUDIT LOG -- jurnal actiuni utilizatori
CREATE TABLE IF NOT EXISTS audit_log (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT        NOT NULL,
  user_name     TEXT        NOT NULL DEFAULT '',
  actiune       TEXT        NOT NULL,
  entitate      TEXT        NOT NULL,
  entitate_id   TEXT,
  detalii       TEXT,
  ip_address    TEXT,
  timestamp     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- MIGRARI -- adauga coloane noi la tabele existente (idempotent)
-- Necesare cand baza de date exista deja cu schema veche.
-- ============================================================

ALTER TABLE users     ADD COLUMN IF NOT EXISTS photo_url      TEXT;

ALTER TABLE documents ADD COLUMN IF NOT EXISTS transaction_id UUID        REFERENCES transactions(id) ON DELETE SET NULL;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS contract_id    UUID        REFERENCES contracts(id)    ON DELETE SET NULL;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS auction_id     UUID        REFERENCES auctions(id)     ON DELETE SET NULL;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_at    TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_by    TEXT        REFERENCES users(uid)       ON DELETE SET NULL;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_url       TEXT        NOT NULL DEFAULT '';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_type      TEXT        NOT NULL DEFAULT 'pdf';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size      BIGINT      NOT NULL DEFAULT 0;

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS ip_address TEXT;

-- ============================================================
-- INDECSI -- performanta interogari frecvente
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_properties_tip           ON properties(tip);
CREATE INDEX IF NOT EXISTS idx_properties_status        ON properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_localitate    ON properties(localitate);
CREATE INDEX IF NOT EXISTS idx_properties_created_at    ON properties(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_prop        ON transactions(property_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status      ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at  ON transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_contracts_prop           ON contracts(property_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status         ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_data_final     ON contracts(data_final);

CREATE INDEX IF NOT EXISTS idx_auctions_prop            ON auctions(property_id);
CREATE INDEX IF NOT EXISTS idx_auctions_status          ON auctions(status);
CREATE INDEX IF NOT EXISTS idx_auctions_data_final      ON auctions(data_final);

CREATE INDEX IF NOT EXISTS idx_bids_auction             ON bids(auction_id);
CREATE INDEX IF NOT EXISTS idx_bids_participant         ON bids(participant_id);

CREATE INDEX IF NOT EXISTS idx_documents_property       ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_documents_transaction    ON documents(transaction_id);
CREATE INDEX IF NOT EXISTS idx_documents_contract       ON documents(contract_id);
CREATE INDEX IF NOT EXISTS idx_documents_auction        ON documents(auction_id);
CREATE INDEX IF NOT EXISTS idx_documents_tip            ON documents(tip);
CREATE INDEX IF NOT EXISTS idx_documents_status         ON documents(status);

CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp      ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_user           ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_entitate       ON audit_log(entitate);
CREATE INDEX IF NOT EXISTS idx_bid_criteria_bid ON bid_criteria(bid_id);
