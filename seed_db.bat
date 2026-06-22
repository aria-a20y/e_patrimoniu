@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo ========================================
echo  Populez baza de date PostgreSQL Render
echo ========================================
echo.
node backend/seed_pg.js
echo.
if %ERRORLEVEL% equ 0 (
    echo ✓ Seeding reusit! Reincarca aplicatia.
) else (
    echo ✗ Eroare la seeding. Verifica conexiunea la internet.
)
pause
