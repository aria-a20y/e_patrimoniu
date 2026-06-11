@echo off
setlocal EnableDelayedExpansion
title e-Patrimoniu - Install Firebase CLI + Configure
color 0A

set "FLUTTER_BIN=%USERPROFILE%\flutter\bin"
set "PUB_CACHE_BIN=%USERPROFILE%\AppData\Local\Pub\Cache\bin"
set "PATH=%FLUTTER_BIN%;%PUB_CACHE_BIN%;%PATH%"

cd /d "%~dp0"

echo.
echo  ==========================================
echo    PASUL 1: Instalare Firebase CLI
echo  ==========================================
echo.

:: Verifica daca firebase CLI e deja instalat
where firebase >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  [OK] Firebase CLI deja instalat.
    firebase --version
) else (
    echo  Instalare firebase-tools via npm...
    npm install -g firebase-tools
    if %ERRORLEVEL% NEQ 0 (
        echo  [EROARE] npm install a esuat. Verifica ca Node.js e instalat.
        pause
        exit /b 1
    )
    echo  [OK] Firebase CLI instalat!
)

echo.
echo  ==========================================
echo    PASUL 2: Autentificare Firebase
echo  ==========================================
echo.
echo  Se va deschide browserul pentru autentificare Google...
echo  Autentifica-te cu contul tau Google in browser.
echo.

firebase login --no-localhost

if %ERRORLEVEL% NEQ 0 (
    echo  [EROARE] Autentificare esuat. Incearca din nou.
    pause
    exit /b 1
)

echo  [OK] Autentificat cu succes!

echo.
echo  ==========================================
echo    PASUL 3: FlutterFire Configure
echo  ==========================================
echo.

call flutterfire configure --project=e-patrimoniu --platforms=android,web

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [EROARE] flutterfire configure a esuat.
    pause
    exit /b 1
)

echo.
echo  ==========================================
echo  [OK] firebase_options.dart generat!
echo  ==========================================
echo.
echo  Ruleaza aplicatia WEB?  (Y=da, N=nu)
choice /c YN /n /m "Alege (Y/N): "
if %ERRORLEVEL% EQU 1 (
    echo.
    echo  Pornire flutter run -d chrome...
    call flutter run -d chrome
)

pause
