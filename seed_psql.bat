@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo ========================================
echo  Populez baza de date cu psql
echo ========================================
echo.

set PGPASSWORD=yBXarNlKJIDMYAGVjLUczOVQZAm9EgNY
set PGHOST=dpg-d8qmubh194ac7393udk0-a.ohio-postgres.render.com
set PGPORT=5432
set PGDATABASE=e_patrimoniu_db
set PGUSER=e_patrimoniu_db_user

set PSQL="D:\postgresql\17\bin\psql.exe"

echo [1] Verific ca psql exista...
if not exist %PSQL% (
    echo EROARE: psql nu gasit la D:\postgresql\17\bin\psql.exe
    pause
    exit /b 1
)
echo psql gasit OK.

echo.
echo [2] Rulare schema.sql...
%PSQL% -f backend\schema.sql
if %ERRORLEVEL% neq 0 (
    echo EROARE la schema.sql! Cod: %ERRORLEVEL%
    pause
    exit /b 1
)
echo Schema OK.

echo.
echo [3] Rulare seed.sql...
%PSQL% -f backend\seed.sql
if %ERRORLEVEL% neq 0 (
    echo EROARE la seed.sql! Cod: %ERRORLEVEL%
    pause
    exit /b 1
)
echo Date demo inserate!

echo.
echo [4] Verific numarul de inregistrari...
%PSQL% -c "SELECT 'properties: ' || COUNT(*) FROM properties;"
%PSQL% -c "SELECT 'users: ' || COUNT(*) FROM users;"

echo.
echo ========================================
echo  GATA! Baza de date are date demo.
echo ========================================
pause
