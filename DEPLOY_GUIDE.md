# Ghid de Deployment — e-Patrimoniu

**Stack:** Flutter Web (Vercel) + Node.js/Express (Render) + Firebase (Auth, Firestore, Storage)

---

## Pas 1 — Pregătire GitHub

Aplicația trebuie pusă pe GitHub înainte de deploy.

```powershell
# Din folderul proiectului (e_patrimoniu/)
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TU/e-patrimoniu.git
git push -u origin main
```

> Asigură-te că `.gitignore` este corect — cheia Firebase **NU** trebuie să apară în commit.

---

## Pas 2 — Obține Service Account Key (Firebase)

1. Deschide [Firebase Console](https://console.firebase.google.com) → proiect **e-patrimoniu**
2. Setări (roată) → **Project Settings** → tab **Service accounts**
3. Click **Generate new private key** → descarcă JSON-ul
4. **NU** muta fișierul în folderul proiectului — rămâne pe desktop sau în alt loc sigur
5. Deschide fișierul JSON în Notepad, selectează tot (`Ctrl+A`), copiază (`Ctrl+C`)

---

## Pas 3 — Deploy Backend pe Render

1. Mergi la [render.com](https://render.com) → Log in cu GitHub
2. **New** → **Web Service** → conectează repo-ul `e-patrimoniu`
3. Setări Render:
   - **Name:** `e-patrimoniu-api`
   - **Region:** Frankfurt (EU Central)
   - **Branch:** `main`
   - **Build Command:** `cd backend && npm install --production`
   - **Start Command:** `cd backend && node index.js`
   - **Plan:** Free
4. În secțiunea **Environment Variables**, adaugă:

   | Key | Value |
   |-----|-------|
   | `NODE_ENV` | `production` |
   | `FIREBASE_SERVICE_ACCOUNT` | *(conținutul JSON copiat la Pas 2 — pe o singură linie)* |
   | `ALLOWED_ORIGIN` | `https://e-patrimoniu.vercel.app` *(actualizează după deploy Vercel)* |

5. Click **Create Web Service**
6. Așteaptă build-ul (~2 min). Testează: `https://e-patrimoniu-api.onrender.com/api/health`
   - Răspuns așteptat: `{"status":"ok","service":"e-patrimoniu-api",...}`

> **Notă Free Tier Render:** serviciul se oprește după 15 min inactivitate și se reîncarcă la primul request (~30 sec).

---

## Pas 4 — Build Flutter Web

Deschide un terminal în folderul `e_patrimoniu/` și rulează:

```powershell
flutter build web --release --dart-define=BACKEND_URL=https://e-patrimoniu-api.onrender.com
```

Fișierele generate sunt în `build/web/`.

---

## Pas 5 — Deploy Frontend pe Vercel

### Opțiunea A — Deploy din GitHub (recomandat)

1. Mergi la [vercel.com](https://vercel.com) → **Add New Project** → importă `e-patrimoniu`
2. **Framework Preset:** Other
3. **Output Directory:** `build/web`
4. **Build Command:** `flutter build web --release --dart-define=BACKEND_URL=https://e-patrimoniu-api.onrender.com`
5. În **Environment Variables** (opțional, pentru build):
   - `BACKEND_URL` = `https://e-patrimoniu-api.onrender.com`
6. Click **Deploy**

> **Problemă potențială:** Vercel nu are Flutter instalat implicit. Dacă build-ul eșuează, folosește Opțiunea B.

### Opțiunea B — Deploy manual (fișiere pre-buildate)

```powershell
# Instalează Vercel CLI
npm install -g vercel

# Din folderul proiectului
vercel --prod --yes \
  --local-config vercel.json \
  build/web
```

La prima rulare, Vercel CLI îți va cere să te autentifici.

---

## Pas 6 — Actualizare CORS pe Render

După ce ai URL-ul Vercel (ex: `https://e-patrimoniu-xyz.vercel.app`):

1. Render Dashboard → **e-patrimoniu-api** → **Environment**
2. Actualizează `ALLOWED_ORIGIN` cu URL-ul exact al aplicației tale Vercel
3. Render va redeploya automat

---

## Pas 7 — Verificare finală

| Verificare | URL |
|---|---|
| Backend health | `https://e-patrimoniu-api.onrender.com/api/health` |
| Frontend | `https://e-patrimoniu.vercel.app` |
| Login | Încearcă autentificarea cu un cont Firebase |

---

## Variabile de mediu — Rezumat

### Render (backend)
| Variabilă | Valoare |
|---|---|
| `NODE_ENV` | `production` |
| `FIREBASE_SERVICE_ACCOUNT` | Conținut JSON service account (secret!) |
| `ALLOWED_ORIGIN` | URL-ul Vercel al aplicației |

### Build Flutter (vercel / local)
| Variabilă | Valoare |
|---|---|
| `BACKEND_URL` | `https://e-patrimoniu-api.onrender.com` |

---

## Troubleshooting

**Backend nu pornește pe Render:**
- Verifică log-urile Render → dacă apare `FIREBASE_SERVICE_ACCOUNT is not valid JSON`, JSON-ul copiat are line breaks; folosește un JSON minifier online înainte de a-l lipi.

**CORS error în browser:**
- Verifică că `ALLOWED_ORIGIN` pe Render este exact URL-ul Vercel (fără `/` la final).

**Flutter app nu se conectează la backend:**
- Verifică în browser DevTools → Network → că request-urile merg la `https://e-patrimoniu-api.onrender.com`, nu la `http://localhost:10000`.
- Dacă merge la localhost, build-ul nu a inclus `--dart-define=BACKEND_URL=...`.

**Render free tier timeout:**
- Normal — primul request după inactivitate durează ~30 sec. Upgrade la Starter ($7/lună) elimină problema.
