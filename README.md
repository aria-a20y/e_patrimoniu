# e-Patrimoniu 🏛️

**Aplicație Flutter + Firebase pentru evidența bunurilor imobiliare ale unităților administrativ-teritoriale (UAT) din România.**

---

## Cuprins

1. [Cerințe sistem](#cerinte-sistem)
2. [Configurare Firebase NOU](#configurare-firebase)
3. [Instalare proiect](#instalare)
4. [Structura proiectului](#structura)
5. [Module disponibile](#module)
6. [Rulare](#rulare)
7. [Configurare Gemini AI](#gemini-ai)
8. [Schema PostgreSQL](#postgresql)
9. [Deployment web](#deployment)

---

## Cerinte sistem

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Firebase CLI + FlutterFire CLI
- Un cont Google (pentru Firebase)
- Opțional: cheie API Google Gemini (pentru Asistentul AI)

---

## Configurare Firebase

> ⚠️ **IMPORTANT**: e-Patrimoniu necesită un proiect Firebase **complet nou**. Nu reutiliza configurarea din alt proiect.

### Pasul 1 – Creare proiect Firebase

1. Accesează [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Adaugă proiect**
3. Denumire: `e-patrimoniu` (sau `epatrimoniu-[judet]`)
4. Dezactivează Google Analytics (opțional)
5. Click **Creare proiect**

### Pasul 2 – Activare servicii Firebase

În consola Firebase, activează:

**Authentication:**
- Build → Authentication → Get started
- Sign-in method → Email/Password → Enable

**Firestore Database:**
- Build → Firestore Database → Create database
- Alege modul **production** sau **test** (test pentru dezvoltare)
- Alege regiunea: `europe-west1` (Belgia) sau `europe-west3` (Frankfurt)

**Storage:**
- Build → Storage → Get started
- Alege aceeași regiune ca Firestore

### Pasul 3 – Reguli Firestore (copiază în Rules)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Utilizatorii autentificați pot citi
    match /{document=**} {
      allow read: if request.auth != null;
    }
    // Utilizatorii autentificați pot scrie
    match /users/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /properties/{id} {
      allow write: if request.auth != null;
    }
    match /documents/{id} {
      allow write: if request.auth != null;
    }
    match /transactions/{id} {
      allow write: if request.auth != null;
    }
    match /contracts/{id} {
      allow write: if request.auth != null;
    }
    match /auctions/{id} {
      allow write: if request.auth != null;
    }
    match /chat_sessions/{id} {
      allow write: if request.auth != null;
    }
    match /chat_messages/{id} {
      allow write: if request.auth != null;
    }
    match /audit_log/{id} {
      allow write: if request.auth != null;
    }
    match /scan_tasks/{id} {
      allow write: if request.auth != null;
    }
  }
}
```

**Reguli Storage:**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /documents/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Pasul 4 – Configurare FlutterFire

```bash
# Instalare FlutterFire CLI
dart pub global activate flutterfire_cli

# În folderul proiectului e_patrimoniu:
flutterfire configure

# Selectează proiectul creat la Pasul 1
# Selectează platformele: web, android, ios (sau doar web pentru început)
# Fișierul firebase_options.dart va fi generat automat!
```

---

## Instalare

```bash
# 1. Navighează în folderul proiectului
cd e_patrimoniu

# 2. Instalare dependențe Flutter
flutter pub get

# 3. Configurare Firebase (după pașii de mai sus)
flutterfire configure

# 4. Verificare setup
flutter doctor
```

### Font Inter

Descarcă fontul Inter și plasează-l în `assets/fonts/`:
- [https://fonts.google.com/specimen/Inter](https://fonts.google.com/specimen/Inter)

Fișiere necesare:
- `assets/fonts/Inter-Regular.ttf`
- `assets/fonts/Inter-Medium.ttf`
- `assets/fonts/Inter-SemiBold.ttf`
- `assets/fonts/Inter-Bold.ttf`

---

## Structura proiectului

```
e_patrimoniu/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── e_patrimoniu_app.dart              # MaterialApp + AuthGate
│   ├── firebase_options.dart              # Generat de FlutterFire CLI
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart            # Constante, colecții Firestore
│   │   ├── models/
│   │   │   ├── property/property_model.dart
│   │   │   ├── document/document_model.dart
│   │   │   ├── transaction/transaction_model.dart
│   │   │   ├── contract/contract_model.dart
│   │   │   ├── auction/auction_model.dart
│   │   │   ├── user/user_model.dart
│   │   │   └── audit/audit_log_model.dart
│   │   └── services/
│   │       ├── auth_service.dart          # Firebase Auth + Firestore users
│   │       ├── audit_service.dart         # Jurnal de audit
│   │       ├── property_service.dart      # CRUD bunuri imobiliare
│   │       ├── document_service.dart      # Upload + management documente
│   │       ├── other_services.dart        # Transaction, Contract, Auction
│   │       ├── scan_service.dart          # OCR / Scanare documente
│   │       └── ai_service.dart            # Gemini AI + chat sessions
│   └── ui/
│       ├── theme/app_theme.dart           # Tema verde e-Patrimoniu
│       ├── styles/auth_styles.dart        # Stiluri ecrane autentificare
│       ├── widgets/shared_widgets.dart    # StatCard, StatusBadge, EmptyState etc.
│       └── screens/
│           ├── auth/
│           │   ├── login.dart
│           │   ├── register.dart
│           │   └── reset_password.dart
│           ├── main_layout.dart           # Sidebar desktop + BottomNav mobile
│           └── features/
│               ├── dashboard/dashboard_screen.dart
│               ├── properties/
│               │   ├── properties_screen.dart
│               │   ├── property_form.dart
│               │   └── property_detail.dart
│               ├── documents/documents_screen.dart
│               ├── scanning/scanning_screen.dart
│               ├── transactions/transactions_screen.dart
│               ├── contracts/contracts_screen.dart
│               ├── auctions/auctions_screen.dart
│               ├── ai/ai_assistant_screen.dart
│               ├── users/users_screen.dart
│               ├── audit/audit_screen.dart
│               └── coming_soon_screen.dart
├── assets/
│   └── fonts/                             # Inter font files
├── pubspec.yaml
└── schema_postgresql.sql                  # Schema PostgreSQL (opțional)
```

---

## Module disponibile

| # | Modul | Status | Descriere |
|---|-------|--------|-----------|
| 1 | 📊 Dashboard | ✅ Complet | Statistici, grafice, activitate recentă |
| 2 | 🏢 Bunuri Imobile | ✅ Complet | CRUD, filtrare, tabel + card view |
| 3 | 📁 Documente | ✅ Complet | Upload, filtrare, verificare OCR |
| 4 | 📄 Scanare | ✅ Complet | OCR 4 pași, extragere date cadastrale |
| 5 | 🔄 Tranzacții | ✅ Complet | Toate tipurile de tranzacții imobiliare |
| 6 | 📝 Contracte | ✅ Complet | Gestionare contracte, alerte expirare |
| 7 | 🔨 Licitații | ✅ Complet | Licitații online, oferte, câștigători |
| 8 | 🤖 Asistent AI | ✅ Complet | Chat Gemini, sesiuni, istoric |
| 9 | 👥 Utilizatori | ✅ Complet | Roluri, status, management |
| 10 | 📋 Jurnal Audit | ✅ Complet | Toate acțiunile înregistrate |
| 11 | 💳 Plăți | 🔜 Curând | Integrare Ghișeul.ro |
| 12 | 🖥️ Ghișeul.ro | 🔜 Curând | Portal plăți online |
| 13 | 📊 ANAF/SPV | 🔜 Curând | Integrare ANAF |
| 14 | 🗺️ ANCPI | 🔜 Curând | Integrare cadastru |
| 15 | 🔔 Notificări | 🔜 Curând | Alerte automate |
| 16 | 📈 Rapoarte | 🔜 Curând | Rapoarte avansate |
| 17 | 🌐 Portal public | 🔜 Curând | Portal public licitații |
| 18 | 📚 Registre | 🔜 Curând | Integrare registre |

---

## Rulare

```bash
# Web (recomandat pentru dezvoltare)
flutter run -d chrome

# Web cu hot reload
flutter run -d chrome --web-renderer html

# Android
flutter run -d android

# iOS (macOS necesar)
flutter run -d ios

# Build web pentru producție
flutter build web --release
```

---

## Gemini AI

Pentru a activa Asistentul AI:

1. Accesează [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Creează o cheie API
3. În fișierul `lib/core/services/ai_service.dart`, înlocuiește:

```dart
static const String _apiKey = 'INSEREAZA_CHEIA_TA_API_GEMINI_AICI';
```

cu cheia ta reală.

> Fără cheie API, asistentul funcționează în mod **demo** cu răspunsuri predefinite despre patrimoniu.

---

## PostgreSQL

Schema completă se află în `schema_postgresql.sql`. Include:

- 17 tabele principale
- Indexuri pentru performanță
- Triggere pentru `updated_at`
- Views utile (contracte expirate, licitații active, statistici)
- Comentarii detaliate

```bash
# Creare bază de date și aplicare schemă
createdb epatrimoniu
psql -d epatrimoniu -f schema_postgresql.sql
```

> **Notă**: Aplicația folosește **Firestore** ca bază de date principală. Schema PostgreSQL este furnizată pentru cazurile în care se dorește o bază de date relațională alternativă sau pentru rapoarte complexe.

---

## Deployment web

```bash
# Build producție
flutter build web --release --web-renderer canvaskit

# Folderul generat: build/web/
# Poate fi găzduit pe:
# - Firebase Hosting
# - Nginx
# - Apache
# - Netlify / Vercel
```

### Firebase Hosting

```bash
# Instalare Firebase CLI
npm install -g firebase-tools

# Login și inițializare
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

---

## Contact și suport

- 📧 Email: suport@epatrimoniu.ro
- 📖 Documentație: https://docs.epatrimoniu.ro

---

*e-Patrimoniu © 2025 – Evidența modernă a patrimoniului public*
