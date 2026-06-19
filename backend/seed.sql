-- ============================================================
-- SEED DATA - e_Patrimoniu (minim 5 înregistrări per tabelă)
-- Rulează DUPĂ schema.sql
-- ============================================================

-- 1. USERS
INSERT INTO users (uid, "firstName", "lastName", email, phone, role, status, departament) VALUES
('user_admin_001', 'Alexandru', 'Ionescu',    'alex.ionescu@primarie.ro',    '0721000001', 'administrator', 'activ', 'Direcția Patrimoniu'),
('user_func_001',  'Maria',     'Popescu',    'maria.popescu@primarie.ro',   '0721000002', 'functionar',    'activ', 'Serviciul Evidență'),
('user_func_002',  'Ion',       'Dumitrescu', 'ion.dumitrescu@primarie.ro',  '0721000003', 'functionar',    'activ', 'Compartiment Juridic'),
('user_func_003',  'Elena',     'Constantin', 'elena.constantin@primarie.ro','0721000004', 'functionar',    'activ', 'Direcția Patrimoniu'),
('user_ext_001',   'George',    'Marinescu',  'george.marinescu@email.ro',   '0721000005', 'extern',        'activ', NULL),
('user_ext_002',   'Ana',       'Gheorghe',   'ana.gheorghe@email.ro',       '0721000006', 'extern',        'activ', NULL)
ON CONFLICT (uid) DO NOTHING;

-- 2. PROPERTIES
INSERT INTO properties (id, denumire, tip, adresa, localitate, domeniu_juridic, numar_cadastral, numar_carte_f, suprafata, valoare_inventar, destinatie, status, descriere, created_by) VALUES
('a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',          'teren',      'Str. Florilor nr. 12',   'Cluj-Napoca','public', '123456','CF-456789',1250.00, 85000.00, 'Spațiu verde public',          'activ','Teren în domeniu public, str. Florilor','user_admin_001'),
('a0000002-0002-0002-0002-000000000002','Clădire Primărie Sector 2',           'cladire',    'B-dul Unirii nr. 5',     'București',  'public', '234567','CF-567890',3200.00,1500000.00,'Sediu administrativ primărie', 'activ','Clădire P+3, sediu Primăriei Sector 2','user_admin_001'),
('a0000003-0003-0003-0003-000000000003','Spațiu Comercial Piața Centrală',     'spatiu',     'Piața Centrală nr. 1',   'Timișoara',  'privat', '345678','CF-678901',450.00, 320000.00, 'Spațiu comercial zona centrală','activ','Spațiu comercial parter, zonă centrală','user_func_001'),
('a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',          'teren',      'Str. Industriei nr. 44', 'Brașov',     'privat', '456789','CF-789012',8500.00,420000.00, 'Teren activități industriale', 'activ','Teren intravilan destinație industrială','user_func_002'),
('a0000005-0005-0005-0005-000000000005','Construcție Dispensar Medical Rural', 'constructie','Str. Sănătății nr. 3',   'Sibiu',      'public', '567890','CF-890123',680.00, 250000.00, 'Dispensar medical comunal',    'activ','Clădire P, dispensar medical UAT','user_func_001'),
('a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',              'teren',      'Str. Tineretului nr. 10','Iași',        'public', '678901','CF-901234',5200.00,180000.00, 'Parc public recreere',         'activ','Teren amenajat ca parc de recreere','user_admin_001')
ON CONFLICT (id) DO NOTHING;

-- 3. TRANSACTIONS
INSERT INTO transactions (id, property_id, property_denumire, tip, descriere, numar_hcl, data_tranzactie, status, created_by) VALUES
('b0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spațiu Comercial Piața Centrală',    'inchiriere',          'Închiriere spațiu comercial SC Alfa SRL',                'HCL-2024-045','2024-03-15','finalizata','user_admin_001'),
('b0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',         'concesionare',        'Concesionare teren industrial 25 ani SC Beta SA',       'HCL-2024-067','2024-04-20','finalizata','user_func_002'),
('b0000003-0003-0003-0003-000000000003','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',         'dareAdministrare',    'Dare în administrare Direcției Parcuri și Spații Verzi','HCL-2024-089','2024-05-10','aprobata',  'user_admin_001'),
('b0000004-0004-0004-0004-000000000004','a0000005-0005-0005-0005-000000000005','Construcție Dispensar Medical Rural','dareFolosintaGratuita','Dare în folosință gratuită Ministerului Sănătății',     'HCL-2024-112','2024-06-01','inDerulare','user_func_001'),
('b0000005-0005-0005-0005-000000000005','a0000002-0002-0002-0002-000000000002','Clădire Primărie Sector 2',          'modificareValoare',   'Reevaluare imobil conform raport evaluator autorizat',  'HCL-2024-130','2024-07-15','finalizata','user_func_003'),
('b0000006-0006-0006-0006-000000000006','a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',             'dareAdministrare',    'Dare în administrare Direcției de Mediu Iași',          'HCL-2024-155','2024-08-20','initiata',  'user_admin_001')
ON CONFLICT (id) DO NOTHING;

-- 4. CONTRACTS
INSERT INTO contracts (id, property_id, property_denumire, transaction_id, numar_contract, parte_contractanta, data_inceput, data_final, valoare, valuta_moneda, status, note, created_by) VALUES
('c0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spațiu Comercial Piața Centrală',    'b0000001-0001-0001-0001-000000000001','CONTRACT-2024-001','SC Alfa SRL',              '2024-04-01','2027-03-31',  4800.00,'RON','activ',    'Chirie 400 RON/lună + TVA','user_admin_001'),
('c0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',         'b0000002-0002-0002-0002-000000000002','CONTRACT-2024-002','SC Beta SA',               '2024-05-01','2049-04-30',125000.00,'RON','activ',    'Concesiune 25 ani, redevență 5000 RON/an','user_func_002'),
('c0000003-0003-0003-0003-000000000003','a0000005-0005-0005-0005-000000000005','Construcție Dispensar Medical Rural','b0000004-0004-0004-0004-000000000004','CONTRACT-2024-003','Ministerul Sănătății',     '2024-06-15','2026-06-14',     0.00,'RON','activ',    'Folosință gratuită, beneficiarul plătește întreținere','user_func_001'),
('c0000004-0004-0004-0004-000000000004','a0000003-0003-0003-0003-000000000003','Spațiu Comercial Piața Centrală',    NULL,                                  'CONTRACT-2022-015','SC Gamma SRL',             '2022-01-01','2024-12-31',  9600.00,'RON','expirat',  'Contract expirat, spațiu eliberat 31.12.2024','user_func_001'),
('c0000005-0005-0005-0005-000000000005','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',         'b0000003-0003-0003-0003-000000000003','CONTRACT-2024-004','Direcția Parcuri Cluj',    '2024-06-01','2029-05-31',     0.00,'RON','activ',    'Administrare spațiu verde','user_admin_001'),
('c0000006-0006-0006-0006-000000000006','a0000002-0002-0002-0002-000000000002','Clădire Primărie Sector 2',          NULL,                                  'CONTRACT-2023-008','Firma Construcții Delta SRL','2023-03-01','2023-12-31', 85000.00,'RON','finalizat','Lucrări renovare fațadă și acoperiș','user_func_003')
ON CONFLICT (id) DO NOTHING;

-- 5. AUCTIONS
INSERT INTO auctions (id, property_id, property_denumire, titlu, tip_atribuire, pret_pornire, pas_licitare, garantie_participare, data_inceput, data_final, status, descriere, created_by) VALUES
('d0000001-0001-0001-0001-000000000001','a0000003-0003-0003-0003-000000000003','Spațiu Comercial Piața Centrală',    'Licitație închiriere spațiu comercial Piața Centrală 2025',  'inchiriere',   2500.00, 100.00,  500.00,'2025-01-10 09:00:00+02','2025-02-10 17:00:00+02','atribuita','Licitație publică 3 ani','user_admin_001'),
('d0000002-0002-0002-0002-000000000002','a0000004-0004-0004-0004-000000000004','Teren Industrial Zona Nord',         'Concesionare teren industrial zona nord Brașov',              'concesionare', 18000.00,500.00, 3600.00,'2024-09-01 09:00:00+03','2024-10-01 17:00:00+03','atribuita','Concesionare 25 ani, drept de construire','user_func_002'),
('d0000003-0003-0003-0003-000000000003','a0000006-0006-0006-0006-000000000006','Teren Parc Tineretului',             'Licitație activități recreative Parc Tineretului',            'inchiriere',   1000.00,  50.00,  200.00,'2025-03-01 09:00:00+02','2025-04-01 17:00:00+02','publicata','Administrare activități recreative și sportive','user_admin_001'),
('d0000004-0004-0004-0004-000000000004','a0000001-0001-0001-0001-000000000001','Teren Str. Florilor nr. 12',         'Vânzare teren Str. Florilor nr. 12 Cluj-Napoca',              'vanzare',     75000.00,1000.00, 7500.00,'2025-05-01 09:00:00+03','2025-06-01 17:00:00+03','draft',    'Teren domeniu privat, licitație publică conform HCL','user_admin_001'),
('d0000005-0005-0005-0005-000000000005','a0000002-0002-0002-0002-000000000002','Clădire Primărie Sector 2',          'Închiriere săli conferință Clădire Primărie Sector 2',        'inchiriere',    500.00,  25.00,  100.00,'2024-11-01 09:00:00+02','2024-12-01 17:00:00+02','inchisa',  'Săli conferință evenimente corporative 1 an','user_func_003'),
('d0000006-0006-0006-0006-000000000006','a0000005-0005-0005-0005-000000000005','Construcție Dispensar Medical Rural','Concesionare teren aferent dispensar pentru extindere',       'concesionare',  3000.00, 100.00,  600.00,'2025-06-15 09:00:00+03','2025-07-15 17:00:00+03','draft',    'Concesionare 200 mp pentru cabinet stomatologic','user_func_001')
ON CONFLICT (id) DO NOTHING;

-- 6. BIDS
INSERT INTO bids (id, auction_id, participant_id, participant_nume, valoare, data_ora, validata, respinsa) VALUES
('e0000001-0001-0001-0001-000000000001','d0000001-0001-0001-0001-000000000001','user_ext_001','George Marinescu / SC Alfa SRL',  2600.00,'2025-01-20 10:15:00+02',TRUE,FALSE),
('e0000002-0002-0002-0002-000000000002','d0000001-0001-0001-0001-000000000001','user_ext_002','Ana Gheorghe / SC Delta SRL',     2700.00,'2025-01-22 14:30:00+02',TRUE,FALSE),
('e0000003-0003-0003-0003-000000000003','d0000001-0001-0001-0001-000000000001','user_ext_001','George Marinescu / SC Alfa SRL',  2800.00,'2025-02-05 09:45:00+02',TRUE,FALSE),
('e0000004-0004-0004-0004-000000000004','d0000002-0002-0002-0002-000000000002','user_ext_002','Ana Gheorghe / SC Beta SA',      18500.00,'2024-09-15 11:00:00+03',TRUE,FALSE),
('e0000005-0005-0005-0005-000000000005','d0000002-0002-0002-0002-000000000002','user_ext_001','George Marinescu / SC Omega SRL',19000.00,'2024-09-20 15:20:00+03',TRUE,FALSE),
('e0000006-0006-0006-0006-000000000006','d0000005-0005-0005-0005-000000000005','user_ext_002','Ana Gheorghe / Firma Sigma SRL',   525.00,'2024-11-15 10:00:00+02',TRUE,FALSE),
('e0000007-0007-0007-0007-000000000007','d0000005-0005-0005-0005-000000000005','user_ext_001','George Marinescu / Events SRL',    550.00,'2024-11-20 16:30:00+02',TRUE,FALSE)
ON CONFLICT (id) DO NOTHING;

-- UPDATE câștigători licitații
UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / SC Alfa SRL',  oferta_castigatoare=2800.00  WHERE id='d0000001-0001-0001-0001-000000000001';
UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / SC Omega SRL', oferta_castigatoare=19000.00 WHERE id='d0000002-0002-0002-0002-000000000002';
UPDATE auctions SET castigator_id='user_ext_001', castigator_nume='George Marinescu / Events SRL',   oferta_castigatoare=550.00   WHERE id='d0000005-0005-0005-0005-000000000005';

-- 7. AUCTION_PARTICIPANTS
INSERT INTO auction_participants (id, auction_id, user_id) VALUES
('f0000001-0001-0001-0001-000000000001','d0000001-0001-0001-0001-000000000001','user_ext_001'),
('f0000002-0002-0002-0002-000000000002','d0000001-0001-0001-0001-000000000001','user_ext_002'),
('f0000003-0003-0003-0003-000000000003','d0000002-0002-0002-0002-000000000002','user_ext_001'),
('f0000004-0004-0004-0004-000000000004','d0000002-0002-0002-0002-000000000002','user_ext_002'),
('f0000005-0005-0005-0005-000000000005','d0000003-0003-0003-0003-000000000003','user_ext_001'),
('f0000006-0006-0006-0006-000000000006','d0000003-0003-0003-0003-000000000003','user_ext_002'),
('f0000007-0007-0007-0007-000000000007','d0000005-0005-0005-0005-000000000005','user_ext_001'),
('f0000008-0008-0008-0008-000000000008','d0000005-0005-0005-0005-000000000005','user_ext_002')
ON CONFLICT (auction_id, user_id) DO NOTHING;

-- 8. DOCUMENTS
INSERT INTO documents (id, denumire, tip, status, file_url, file_type, file_size, property_id, transaction_id, contract_id, auction_id, numar_document, data_document, emitent, note, uploaded_by) VALUES
('da000001-0001-0001-0001-000000000001','Extras Carte Funciară Spațiu Piața Centrală',      'extrasCF',      'verificat','https://storage.epatrimoniu.ro/docs/cf_001.pdf',  'pdf', 245760,'a0000003-0003-0003-0003-000000000003',NULL,NULL,NULL,'CF-2024-001','2024-02-15','OCPI Timiș','Extras CF actualizat, fără sarcini','user_func_001'),
('da000002-0002-0002-0002-000000000002','HCL nr. 45/2024 - Aprobare închiriere spațiu',     'hcl',           'verificat','https://storage.epatrimoniu.ro/docs/hcl_045.pdf', 'pdf', 512000,'a0000003-0003-0003-0003-000000000003','b0000001-0001-0001-0001-000000000001',NULL,NULL,'HCL-45/2024','2024-03-10','Consiliul Local Timișoara','HCL aprobat 18 voturi pentru','user_admin_001'),
('da000003-0003-0003-0003-000000000003','Contract închiriere SC Alfa SRL 2024-2027',        'contract',      'verificat','https://storage.epatrimoniu.ro/docs/cont_001.pdf','pdf',1048576,'a0000003-0003-0003-0003-000000000003','b0000001-0001-0001-0001-000000000001','c0000001-0001-0001-0001-000000000001',NULL,'CONTRACT-2024-001','2024-04-01','Primăria Timișoara','Contract semnat de ambele părți','user_func_001'),
('da000004-0004-0004-0004-000000000004','Plan Cadastral Teren Industrial Brașov',           'planCadastral', 'verificat','https://storage.epatrimoniu.ro/docs/plan_001.pdf','pdf', 819200,'a0000004-0004-0004-0004-000000000004',NULL,NULL,NULL,'PC-2024-044','2024-03-20','OCPI Brașov','Plan cadastral vizat ANCPI, scara 1:500','user_func_002'),
('da000005-0005-0005-0005-000000000005','Raport Evaluare Clădire Primărie Sector 2',        'raportEvaluare','verificat','https://storage.epatrimoniu.ro/docs/eval_001.pdf','pdf',2097152,'a0000002-0002-0002-0002-000000000002','b0000005-0005-0005-0005-000000000005',NULL,NULL,'RE-2024-007','2024-07-01','Expert Evaluator ANEVAR','Valoare piață: 2.100.000 RON','user_func_003'),
('da000006-0006-0006-0006-000000000006','Proces Verbal Predare-Primire Dispensar Medical',  'procesVerbal',  'verificat','https://storage.epatrimoniu.ro/docs/pv_001.pdf',  'pdf', 153600,'a0000005-0005-0005-0005-000000000005','b0000004-0004-0004-0004-000000000004','c0000003-0003-0003-0003-000000000003',NULL,'PV-2024-012','2024-06-15','Comisie predare-primire','PV semnat UAT și Ministerul Sănătății','user_func_001'),
('da000007-0007-0007-0007-000000000007','HCL nr. 67/2024 - Concesionare teren industrial', 'hcl',           'verificat','https://storage.epatrimoniu.ro/docs/hcl_067.pdf', 'pdf', 491520,'a0000004-0004-0004-0004-000000000004','b0000002-0002-0002-0002-000000000002',NULL,'d0000002-0002-0002-0002-000000000002','HCL-67/2024','2024-04-15','Consiliul Local Brașov','HCL aprobat, publicat pe site primărie','user_admin_001')
ON CONFLICT (id) DO NOTHING;

-- 9. AUDIT_LOG
INSERT INTO audit_log (id, user_id, user_name, actiune, entitate, entitate_id, detalii, ip_address) VALUES
('ab000001-0001-0001-0001-000000000001','user_admin_001','Alexandru Ionescu','CREATE','properties',  'a0000001-0001-0001-0001-000000000001','Adăugat bun imobil: Teren Str. Florilor nr. 12',               '192.168.1.100'),
('ab000002-0002-0002-0002-000000000002','user_func_001', 'Maria Popescu',   'CREATE','contracts',   'c0000001-0001-0001-0001-000000000001','Creat contract închiriere SC Alfa SRL, valoare 4800 RON',       '192.168.1.101'),
('ab000003-0003-0003-0003-000000000003','user_admin_001','Alexandru Ionescu','CREATE','auctions',    'd0000001-0001-0001-0001-000000000001','Publicată licitație spațiu comercial Piața Centrală 2025',     '192.168.1.100'),
('ab000004-0004-0004-0004-000000000004','user_ext_001',  'George Marinescu','CREATE','bids',        'e0000003-0003-0003-0003-000000000003','Depusă ofertă 2800 RON la licitația spațiu comercial',         '10.0.0.55'),
('ab000005-0005-0005-0005-000000000005','user_admin_001','Alexandru Ionescu','UPDATE','auctions',    'd0000001-0001-0001-0001-000000000001','Atribuit câștigător: George Marinescu, ofertă 2800 RON',       '192.168.1.100'),
('ab000006-0006-0006-0006-000000000006','user_func_002', 'Ion Dumitrescu',  'CREATE','transactions','b0000002-0002-0002-0002-000000000002','Inițiată tranzacție concesionare teren industrial Brașov',     '192.168.1.102'),
('ab000007-0007-0007-0007-000000000007','user_func_003', 'Elena Constantin','UPDATE','properties',  'a0000002-0002-0002-0002-000000000002','Actualizată valoare inventar clădire: 1.500.000 RON',          '192.168.1.103'),
('ab000008-0008-0008-0008-000000000008','user_func_001', 'Maria Popescu',   'CREATE','documents',   'da000003-0003-0003-0003-000000000003','Încărcat document: Contract închiriere SC Alfa SRL 2024-2027',  '192.168.1.101'),
('ab000009-0009-0009-0009-000000000009','user_admin_001','Alexandru Ionescu','VIEW',  'reports',     NULL,                                 'Generat raport situație contracte active - iunie 2024',         '192.168.1.100'),
('ab000010-000a-000a-000a-00000000000a','user_ext_002',  'Ana Gheorghe',    'CREATE','bids',        'e0000006-0006-0006-0006-000000000006','Depusă ofertă 525 RON la licitația săli conferință',           '10.0.0.66')
ON CONFLICT (id) DO NOTHING;
