-- ============================================================
-- e-Patrimoniu - Schema PostgreSQL
-- Evidența bunurilor imobiliare ale UAT-urilor
-- Versiunea: 1.0.0
-- ============================================================

-- Extensii necesare
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- pentru căutare full-text

-- ============================================================
-- 1. UTILIZATORI
-- ============================================================
CREATE TABLE utilizatori (
    uid                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid        VARCHAR(128) UNIQUE NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) UNIQUE NOT NULL,
    telefon             VARCHAR(20),
    rol                 VARCHAR(30) NOT NULL DEFAULT 'functionar'
                            CHECK (rol IN ('administrator','functionar','extern')),
    status              VARCHAR(20) NOT NULL DEFAULT 'activ'
                            CHECK (status IN ('activ','inactiv','suspendat')),
    departament         VARCHAR(200),
    photo_url           TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_utilizatori_email ON utilizatori(email);
CREATE INDEX idx_utilizatori_rol ON utilizatori(rol);
CREATE INDEX idx_utilizatori_status ON utilizatori(status);

-- ============================================================
-- 2. BUNURI IMOBILIARE
-- ============================================================
CREATE TABLE bunuri_imobiliare (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    denumire            VARCHAR(500) NOT NULL,
    tip                 VARCHAR(30) NOT NULL
                            CHECK (tip IN ('teren','cladire','spatiu','constructie')),
    adresa              VARCHAR(500) NOT NULL,
    localitate          VARCHAR(200) NOT NULL,
    judet               VARCHAR(100),
    domeniu_juridic     VARCHAR(10) NOT NULL DEFAULT 'public'
                            CHECK (domeniu_juridic IN ('public','privat')),
    numar_cadastral     VARCHAR(50),
    numar_carte_f       VARCHAR(50),
    suprafata           DECIMAL(12,2) NOT NULL DEFAULT 0,   -- mp
    valoare_inventar    DECIMAL(14,2) NOT NULL DEFAULT 0,   -- RON
    destinatie          VARCHAR(500),
    status              VARCHAR(30) NOT NULL DEFAULT 'activ'
                            CHECK (status IN ('activ','inactiv','scosEvidenta','inLitigiu')),
    descriere           TEXT,
    image_url           TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid)
);

CREATE INDEX idx_bunuri_tip ON bunuri_imobiliare(tip);
CREATE INDEX idx_bunuri_domeniu ON bunuri_imobiliare(domeniu_juridic);
CREATE INDEX idx_bunuri_status ON bunuri_imobiliare(status);
CREATE INDEX idx_bunuri_localitate ON bunuri_imobiliare(localitate);
CREATE INDEX idx_bunuri_cadastral ON bunuri_imobiliare(numar_cadastral);
CREATE INDEX idx_bunuri_search ON bunuri_imobiliare USING gin(to_tsvector('romanian', denumire || ' ' || COALESCE(adresa,'') || ' ' || COALESCE(numar_cadastral,'')));

-- ============================================================
-- 3. DOCUMENTE
-- ============================================================
CREATE TABLE documente (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    denumire            VARCHAR(500) NOT NULL,
    tip                 VARCHAR(30) NOT NULL
                            CHECK (tip IN ('hcl','extrasCF','planCadastral','raportEvaluare',
                                          'contract','procesVerbal','actAditional','documentPlata','altele')),
    status              VARCHAR(20) NOT NULL DEFAULT 'neverificat'
                            CHECK (status IN ('neverificat','inVerificare','verificat','respins')),
    file_url            TEXT NOT NULL,
    file_type           VARCHAR(10),    -- pdf, jpg, png, docx
    file_size           BIGINT,         -- bytes
    bun_id              UUID REFERENCES bunuri_imobiliare(id) ON DELETE SET NULL,
    tranzactie_id       UUID,           -- FK adăugat mai jos
    contract_id         UUID,           -- FK adăugat mai jos
    licitatie_id        UUID,           -- FK adăugat mai jos
    note                TEXT,
    uploaded_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    uploaded_by         UUID REFERENCES utilizatori(uid)
);

CREATE INDEX idx_documente_bun ON documente(bun_id);
CREATE INDEX idx_documente_tip ON documente(tip);
CREATE INDEX idx_documente_status ON documente(status);

-- ============================================================
-- 4. SCAN TASKS (OCR)
-- ============================================================
CREATE TABLE scan_tasks (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id         UUID REFERENCES documente(id) ON DELETE CASCADE,
    bun_id              UUID REFERENCES bunuri_imobiliare(id) ON DELETE SET NULL,
    extracted_fields    JSONB,          -- câmpuri extrase de OCR
    confidence_score    DECIMAL(4,2),   -- 0.00 - 1.00
    raw_text            TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'finalizat'
                            CHECK (status IN ('inAsteptare','procesare','finalizat','eroare')),
    verificat_manual    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_scan_document ON scan_tasks(document_id);
CREATE INDEX idx_scan_verificat ON scan_tasks(verificat_manual);

-- ============================================================
-- 5. TRANZACȚII
-- ============================================================
CREATE TABLE tranzactii (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bun_id              UUID NOT NULL REFERENCES bunuri_imobiliare(id),
    bun_denumire        VARCHAR(500),   -- denormalizat pentru performanță
    tip                 VARCHAR(50) NOT NULL
                            CHECK (tip IN ('vanzare','cumparare','inchiriere','concesionare',
                                          'dareAdministrare','dareFolosintaGratuita','comodat',
                                          'schimbImobiliar','transfer','preluarePatrimoniu',
                                          'scoatereEvidenta','modificareValoare')),
    descriere           TEXT,
    numar_hcl           VARCHAR(100) NOT NULL,
    data_tranzactie     DATE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'initiata'
                            CHECK (status IN ('initiata','aprobata','inDerulare','finalizata','anulata')),
    note                TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid)
);

CREATE INDEX idx_tranzactii_bun ON tranzactii(bun_id);
CREATE INDEX idx_tranzactii_tip ON tranzactii(tip);
CREATE INDEX idx_tranzactii_status ON tranzactii(status);
CREATE INDEX idx_tranzactii_data ON tranzactii(data_tranzactie);

-- Legătura documente <-> tranzacții (many-to-many)
CREATE TABLE tranzactii_documente (
    tranzactie_id       UUID NOT NULL REFERENCES tranzactii(id) ON DELETE CASCADE,
    document_id         UUID NOT NULL REFERENCES documente(id) ON DELETE CASCADE,
    PRIMARY KEY (tranzactie_id, document_id)
);

-- ============================================================
-- 6. CONTRACTE
-- ============================================================
CREATE TABLE contracte (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bun_id              UUID NOT NULL REFERENCES bunuri_imobiliare(id),
    bun_denumire        VARCHAR(500),
    tranzactie_id       UUID REFERENCES tranzactii(id),
    numar_contract      VARCHAR(200) NOT NULL UNIQUE,
    parte_contractanta  VARCHAR(500) NOT NULL,
    data_inceput        DATE NOT NULL,
    data_final          DATE NOT NULL,
    valoare             DECIMAL(14,2) NOT NULL DEFAULT 0,
    valuta              VARCHAR(5) NOT NULL DEFAULT 'RON',
    status              VARCHAR(20) NOT NULL DEFAULT 'activ'
                            CHECK (status IN ('activ','prelungit','reziliat','expirat','finalizat','anulat')),
    document_url        TEXT,
    note                TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid),
    CONSTRAINT check_date CHECK (data_final >= data_inceput)
);

CREATE INDEX idx_contracte_bun ON contracte(bun_id);
CREATE INDEX idx_contracte_status ON contracte(status);
CREATE INDEX idx_contracte_data_final ON contracte(data_final);
CREATE INDEX idx_contracte_numar ON contracte(numar_contract);

-- ============================================================
-- 7. MODIFICĂRI CONTRACTE
-- ============================================================
CREATE TABLE modificari_contracte (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id         UUID NOT NULL REFERENCES contracte(id) ON DELETE CASCADE,
    tip                 VARCHAR(30) NOT NULL
                            CHECK (tip IN ('prelungire','reziliere','actualizareChirie',
                                          'actualizareRedeventa','modificareDurata','actAditional')),
    descriere           TEXT NOT NULL,
    data_modificare     DATE NOT NULL,
    document_url        TEXT,
    created_by          UUID REFERENCES utilizatori(uid),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_modif_contract ON modificari_contracte(contract_id);

-- ============================================================
-- 8. LICITAȚII
-- ============================================================
CREATE TABLE licitatii (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bun_id              UUID NOT NULL REFERENCES bunuri_imobiliare(id),
    bun_denumire        VARCHAR(500),
    titlu               VARCHAR(500) NOT NULL,
    tip_atribuire       VARCHAR(20) NOT NULL
                            CHECK (tip_atribuire IN ('vanzare','inchiriere','concesionare')),
    pret_pornire        DECIMAL(14,2) NOT NULL DEFAULT 0,
    pas_licitare        DECIMAL(12,2) NOT NULL DEFAULT 0,
    garantie_participare DECIMAL(12,2) NOT NULL DEFAULT 0,
    data_inceput        TIMESTAMP WITH TIME ZONE NOT NULL,
    data_final          TIMESTAMP WITH TIME ZONE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'draft'
                            CHECK (status IN ('draft','publicata','activa','inchisa','atribuita','anulata','contestata')),
    castigator_id       UUID REFERENCES utilizatori(uid),
    castigator_nume     VARCHAR(500),
    oferta_castigatoare DECIMAL(14,2),
    tranzactie_id       UUID REFERENCES tranzactii(id),
    contract_id         UUID REFERENCES contracte(id),
    descriere           TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid),
    CONSTRAINT check_licitatie_date CHECK (data_final > data_inceput)
);

CREATE INDEX idx_licitatii_bun ON licitatii(bun_id);
CREATE INDEX idx_licitatii_status ON licitatii(status);
CREATE INDEX idx_licitatii_data ON licitatii(data_final);

-- ============================================================
-- 9. PARTICIPANȚI LICITAȚIE
-- ============================================================
CREATE TABLE participanti_licitatie (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    licitatie_id        UUID NOT NULL REFERENCES licitatii(id) ON DELETE CASCADE,
    user_id             UUID REFERENCES utilizatori(uid),
    nume_participant    VARCHAR(500) NOT NULL,
    email               VARCHAR(255),
    cnp_cui             VARCHAR(20),
    garantie_depusa     BOOLEAN NOT NULL DEFAULT FALSE,
    garantie_returnata  BOOLEAN NOT NULL DEFAULT FALSE,
    calificat           BOOLEAN NOT NULL DEFAULT FALSE,
    data_inscriere      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_participanti_licitatie ON participanti_licitatie(licitatie_id);
CREATE UNIQUE INDEX idx_participant_unic ON participanti_licitatie(licitatie_id, COALESCE(user_id::text, email));

-- ============================================================
-- 10. OFERTE LICITAȚIE (BIDS)
-- ============================================================
CREATE TABLE oferte_licitatie (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    licitatie_id        UUID NOT NULL REFERENCES licitatii(id) ON DELETE CASCADE,
    participant_id      UUID REFERENCES participanti_licitatie(id),
    participant_nume    VARCHAR(500) NOT NULL,
    valoare             DECIMAL(14,2) NOT NULL,
    data_ora            TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    validata            BOOLEAN NOT NULL DEFAULT FALSE,
    respinsa            BOOLEAN NOT NULL DEFAULT FALSE,
    motiv_respingere    TEXT
);

CREATE INDEX idx_oferte_licitatie ON oferte_licitatie(licitatie_id);
CREATE INDEX idx_oferte_valoare ON oferte_licitatie(valoare DESC);

-- ============================================================
-- 11. DOCUMENTE LICITAȚIE (many-to-many)
-- ============================================================
CREATE TABLE licitatii_documente (
    licitatie_id        UUID NOT NULL REFERENCES licitatii(id) ON DELETE CASCADE,
    document_id         UUID NOT NULL REFERENCES documente(id) ON DELETE CASCADE,
    PRIMARY KEY (licitatie_id, document_id)
);

-- ============================================================
-- 12. SESIUNI CHAT AI
-- ============================================================
CREATE TABLE sesiuni_chat (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES utilizatori(uid) ON DELETE CASCADE,
    titlu               VARCHAR(500) NOT NULL DEFAULT 'Sesiune nouă',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sesiuni_user ON sesiuni_chat(user_id);

-- ============================================================
-- 13. MESAJE CHAT AI
-- ============================================================
CREATE TABLE mesaje_chat (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sesiune_id          UUID NOT NULL REFERENCES sesiuni_chat(id) ON DELETE CASCADE,
    continut            TEXT NOT NULL,
    is_user             BOOLEAN NOT NULL DEFAULT TRUE,
    timestamp           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_mesaje_sesiune ON mesaje_chat(sesiune_id);
CREATE INDEX idx_mesaje_timestamp ON mesaje_chat(sesiune_id, timestamp);

-- ============================================================
-- 14. JURNAL AUDIT
-- ============================================================
CREATE TABLE jurnal_audit (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID REFERENCES utilizatori(uid),
    user_name           VARCHAR(300),
    actiune             VARCHAR(30) NOT NULL
                            CHECK (actiune IN ('adaugare','modificare','stergere','actualizareStatus',
                                              'incarcarDocument','creareLicitatie','depunereOferta',
                                              'autentificare','deconectare')),
    entitate            VARCHAR(100) NOT NULL,
    entitate_id         UUID,
    detalii             TEXT NOT NULL,
    ip_address          INET,
    user_agent          TEXT,
    data_ora            TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON jurnal_audit(user_id);
CREATE INDEX idx_audit_actiune ON jurnal_audit(actiune);
CREATE INDEX idx_audit_data ON jurnal_audit(data_ora DESC);
CREATE INDEX idx_audit_entitate ON jurnal_audit(entitate, entitate_id);

-- ============================================================
-- 15. PLĂȚI (modul viitor)
-- ============================================================
CREATE TABLE plati (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id         UUID REFERENCES contracte(id),
    tranzactie_id       UUID REFERENCES tranzactii(id),
    suma                DECIMAL(14,2) NOT NULL,
    valuta              VARCHAR(5) NOT NULL DEFAULT 'RON',
    tip_plata           VARCHAR(50),        -- virament, numerar, card
    referinta           VARCHAR(200),
    status              VARCHAR(20) NOT NULL DEFAULT 'asteptata'
                            CHECK (status IN ('asteptata','confirmata','respinsa','anulata')),
    data_scadenta       DATE,
    data_plata          DATE,
    note                TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid)
);

CREATE INDEX idx_plati_contract ON plati(contract_id);
CREATE INDEX idx_plati_status ON plati(status);

-- ============================================================
-- 16. NOTIFICĂRI (modul viitor)
-- ============================================================
CREATE TABLE notificari (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES utilizatori(uid) ON DELETE CASCADE,
    titlu               VARCHAR(500) NOT NULL,
    mesaj               TEXT NOT NULL,
    tip                 VARCHAR(50),        -- contract_expira, licitatie_activa, etc.
    entitate_id         UUID,
    citita              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notificari_user ON notificari(user_id, citita);
CREATE INDEX idx_notificari_created ON notificari(created_at DESC);

-- ============================================================
-- 17. RAPOARTE (modul viitor)
-- ============================================================
CREATE TABLE rapoarte (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    denumire            VARCHAR(500) NOT NULL,
    tip                 VARCHAR(50) NOT NULL,
    parametri           JSONB,
    rezultat_url        TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'in_procesare'
                            CHECK (status IN ('in_procesare','generat','eroare')),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          UUID REFERENCES utilizatori(uid)
);

-- ============================================================
-- FK-URI AMÂNATE (circular references)
-- ============================================================
ALTER TABLE documente ADD CONSTRAINT fk_doc_tranzactie
    FOREIGN KEY (tranzactie_id) REFERENCES tranzactii(id) ON DELETE SET NULL;
ALTER TABLE documente ADD CONSTRAINT fk_doc_contract
    FOREIGN KEY (contract_id) REFERENCES contracte(id) ON DELETE SET NULL;
ALTER TABLE documente ADD CONSTRAINT fk_doc_licitatie
    FOREIGN KEY (licitatie_id) REFERENCES licitatii(id) ON DELETE SET NULL;

-- ============================================================
-- FUNCȚII ȘI TRIGGERE
-- ============================================================

-- Trigger pentru actualizare automată updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bunuri_updated_at
    BEFORE UPDATE ON bunuri_imobiliare
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_utilizatori_updated_at
    BEFORE UPDATE ON utilizatori
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Funcție: calcul valoare totală patrimoniu
CREATE OR REPLACE FUNCTION get_valoare_totala_patrimoniu()
RETURNS DECIMAL AS $$
    SELECT COALESCE(SUM(valoare_inventar), 0)
    FROM bunuri_imobiliare
    WHERE status = 'activ';
$$ LANGUAGE sql STABLE;

-- Funcție: statistici dashboard
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS TABLE (
    total_bunuri BIGINT,
    bunuri_active BIGINT,
    total_contracte BIGINT,
    contracte_active BIGINT,
    licitatii_active BIGINT,
    valoare_patrimoniu DECIMAL
) AS $$
BEGIN
    RETURN QUERY SELECT
        COUNT(*)::BIGINT AS total_bunuri,
        COUNT(*) FILTER (WHERE status = 'activ')::BIGINT AS bunuri_active,
        (SELECT COUNT(*) FROM contracte)::BIGINT AS total_contracte,
        (SELECT COUNT(*) FROM contracte WHERE status = 'activ')::BIGINT AS contracte_active,
        (SELECT COUNT(*) FROM licitatii WHERE status = 'activa')::BIGINT AS licitatii_active,
        get_valoare_totala_patrimoniu() AS valoare_patrimoniu
    FROM bunuri_imobiliare;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- DATE INIȚIALE (seed)
-- ============================================================

-- Administrator implicit (parolă setată prin Firebase Auth)
INSERT INTO utilizatori (firebase_uid, first_name, last_name, email, rol, status)
VALUES
    ('FIREBASE_UID_ADMIN', 'Administrator', 'Sistem', 'admin@epatrimoniu.ro', 'administrator', 'activ')
ON CONFLICT (email) DO NOTHING;

-- ============================================================
-- VIEWS UTILE
-- ============================================================

-- View: contracte care expiră în 30 de zile
CREATE OR REPLACE VIEW v_contracte_expira_curand AS
SELECT c.*, b.denumire AS bun_denumire_complet,
       (c.data_final - CURRENT_DATE) AS zile_ramase
FROM contracte c
JOIN bunuri_imobiliare b ON b.id = c.bun_id
WHERE c.status IN ('activ','prelungit')
  AND c.data_final BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY c.data_final;

-- View: licitații active cu numărul de oferte
CREATE OR REPLACE VIEW v_licitatii_active AS
SELECT l.*,
       COUNT(o.id) AS numar_oferte,
       MAX(o.valoare) AS oferta_maxima
FROM licitatii l
LEFT JOIN oferte_licitatie o ON o.licitatie_id = l.id AND o.validata = TRUE
WHERE l.status IN ('activa','publicata')
GROUP BY l.id
ORDER BY l.data_final;

-- View: statistici bunuri pe tip
CREATE OR REPLACE VIEW v_statistici_bunuri AS
SELECT
    tip,
    domeniu_juridic,
    COUNT(*) AS numar,
    SUM(suprafata) AS suprafata_totala,
    SUM(valoare_inventar) AS valoare_totala,
    AVG(valoare_inventar) AS valoare_medie
FROM bunuri_imobiliare
WHERE status = 'activ'
GROUP BY tip, domeniu_juridic
ORDER BY tip, domeniu_juridic;

-- ============================================================
-- COMENTARII TABELE
-- ============================================================
COMMENT ON TABLE utilizatori IS 'Utilizatori aplicație e-Patrimoniu (sincronizați cu Firebase Auth)';
COMMENT ON TABLE bunuri_imobiliare IS 'Registrul bunurilor imobiliare ale UAT';
COMMENT ON TABLE documente IS 'Documente atașate bunurilor, tranzacțiilor, contractelor și licitațiilor';
COMMENT ON TABLE scan_tasks IS 'Rezultate procesare OCR pentru documente scanate';
COMMENT ON TABLE tranzactii IS 'Tranzacții imobiliare (vânzare, închiriere, concesionare etc.)';
COMMENT ON TABLE contracte IS 'Contracte de administrare a patrimoniului';
COMMENT ON TABLE modificari_contracte IS 'Istoricul modificărilor unui contract';
COMMENT ON TABLE licitatii IS 'Licitații online pentru atribuirea bunurilor';
COMMENT ON TABLE participanti_licitatie IS 'Participanții înregistrați la o licitație';
COMMENT ON TABLE oferte_licitatie IS 'Ofertele depuse în cadrul licitațiilor';
COMMENT ON TABLE sesiuni_chat IS 'Sesiuni de conversație cu Asistentul AI';
COMMENT ON TABLE mesaje_chat IS 'Mesajele din sesiunile de chat cu AI';
COMMENT ON TABLE jurnal_audit IS 'Jurnalul de audit - toate acțiunile utilizatorilor';
COMMENT ON TABLE plati IS 'Înregistrări de plăți (modul viitor)';
COMMENT ON TABLE notificari IS 'Notificări pentru utilizatori (modul viitor)';
COMMENT ON TABLE rapoarte IS 'Rapoarte generate (modul viitor)';
