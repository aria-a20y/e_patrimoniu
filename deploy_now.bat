@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo ========================================
echo  1. Flutter build web cu URL corect
echo ========================================
flutter build web --release --dart-define=BACKEND_URL=https://e-patrimoniu-api.onrender.com
if %ERRORLEVEL% neq 0 (
    echo EROARE la build! Cod: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)
echo Build reusit!

echo.
echo ========================================
echo  2. Git config
echo ========================================
git config user.name "aria-a20y"
git config user.email "dariageo27@gmail.com"

echo.
echo ========================================
echo  3. Adaug fisierele modificate
echo ========================================
git add .gitignore vercel.json
git add build/web
git add backend/db.js
echo Fisiere adaugate.

echo.
echo ========================================
echo  4. Commit
echo ========================================
git commit -m "feat: seed automat baza de date la pornire (minim 7 randuri/tabela)"
if %ERRORLEVEL% neq 0 (
    echo Nimic de commit sau eroare. Continui cu push...
)

echo.
echo ========================================
echo  5. Push pe GitHub
echo ========================================
git push origin main
if %ERRORLEVEL% neq 0 (
    echo EROARE la push! Verifica conexiunea sau autentificarea GitHub.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo  GATA! Vercel va face deploy automat.
echo  Verificati: https://e-patrimoniu-u5qw.vercel.app
echo ========================================
pause
