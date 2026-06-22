@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo ========================================
echo  Push backend/db.js pe GitHub (fara rebuild Flutter)
echo ========================================
echo.

git config user.name "aria-a20y"
git config user.email "dariageo27@gmail.com"

git add backend/db.js
git commit -m "feat: seed automat baza de date la pornire (minim 7 randuri/tabela)"

if %ERRORLEVEL% neq 0 (
    echo Nimic de commit (fisier poate deja push-uit). Continui cu push...
)

git push origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================
    echo  GATA! Render va redeploya automat.
    echo  In ~1-2 min datele demo vor aparea in app.
    echo  Verifica: https://e-patrimoniu-u5qw.vercel.app
    echo ========================================
) else (
    echo EROARE la push! Verifica conexiunea sau autentificarea GitHub.
)

pause
