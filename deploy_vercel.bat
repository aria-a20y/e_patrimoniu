@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo === Setez autorul git ===
git config user.name "aria-a20y"
git config user.email "dariageo27@gmail.com"

echo.
echo === Flutter build web ===
flutter build web --release

echo.
echo === Adaug build/web (force, era in .gitignore) ===
git add -f build/web

echo.
echo === Adaug restul fisierelor modificate ===
git add vercel.json .gitignore

echo.
echo === Commit ===
git commit -m "Deploy Vercel: adaug build/web pre-built, fix vercel.json framework=null"

echo.
echo === Push ===
git push origin main

echo.
echo === DONE - Vercel va detecta commit-ul si va face deploy ===
pause
