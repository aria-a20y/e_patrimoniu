@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo ========================================
echo  Instalez pg global + seed PostgreSQL
echo ========================================
echo.

echo [1] npm install -g pg ...
npm install -g pg
echo Instalare pg globala terminata.

echo.
echo [2] Gasesc calea npm global...
for /f "tokens=*" %%i in ('npm root -g') do set NPM_GLOBAL=%%i
echo NPM global path: %NPM_GLOBAL%

echo.
echo [3] Rulez seed_pg.js cu NODE_PATH...
set NODE_PATH=%NPM_GLOBAL%
node backend\seed_pg.js
echo.
if %ERRORLEVEL% equ 0 (
    echo SUCCES! Baza de date are date demo.
) else (
    echo EROARE la seed. Cod: %ERRORLEVEL%
)
pause
