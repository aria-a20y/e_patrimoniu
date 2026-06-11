@echo off
setlocal EnableDelayedExpansion
title e-Patrimoniu - Firebase Login + Configure
color 0A

set "FLUTTER_BIN=%USERPROFILE%\flutter\bin"
set "PUB_CACHE_BIN=%USERPROFILE%\AppData\Local\Pub\Cache\bin"
set "NPM_BIN=%APPDATA%\npm"
set "PATH=%FLUTTER_BIN%;%PUB_CACHE_BIN%;%NPM_BIN%;%PATH%"

cd /d "%~dp0"

echo.
echo  ==========================================
echo    Verificare Firebase CLI...
echo  ==========================================
echo.

where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  [EROARE] firebase CLI nu e gasit in PATH.
    echo  Adauga manual: %APPDATA%\npm la PATH sau reinstaleaza.
    pause
    exit /b 1
)

firebase --version
echo  [OK] Firebase CLI gasit!

echo.
echo  ==========================================
echo    PASUL 1: Autentificare Firebase
echo  ==========================================
echo.
echo  Se va deschide browserul pentru autentificare Google.
echo  Autentifica-te si copiaza codul de autorizare inapoi in terminal.
echo.

firebase login

if %ERRORLEVEL% NEQ 0 (
    echo  [EROARE] Autentificare esuat.
    pause
    exit /b 1
)

echo  [OK] Autentificat!

echo.
echo  ==========================================
echo    PASUL 2: FlutterFire Configure
echo  ==========================================
echo.

call flutterfire configure --project=e-patrimoniu --platforms=android,web --yes

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [EROARE] flutterfire configure a esuat.
    pause
    exit /b 1
)

echo.
echo  ==========================================
echo  [OK] firebase_options.dart generat cu succes!
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
