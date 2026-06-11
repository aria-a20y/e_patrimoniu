@echo off
setlocal EnableDelayedExpansion
title e-Patrimoniu - Firebase Configure
color 0B

echo.
echo  ==========================================
echo    e-Patrimoniu - Configurare Firebase
echo  ==========================================
echo.

:: Seteaza PATH corect pentru Flutter si flutterfire
set "FLUTTER_BIN=%USERPROFILE%\flutter\bin"
set "PUB_CACHE_BIN=%USERPROFILE%\AppData\Local\Pub\Cache\bin"

:: Verifica Flutter
if exist "%FLUTTER_BIN%\flutter.bat" (
    set "PATH=%FLUTTER_BIN%;%PATH%"
    echo  [OK] Flutter: %FLUTTER_BIN%
) else (
    where flutter >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo  [EROARE] Flutter nu a fost gasit. Ruleaza mai intai SETUP_FLUTTER.bat
        exit /b 1
    )
)

:: Verifica flutterfire
if exist "%PUB_CACHE_BIN%\flutterfire.bat" (
    set "PATH=%PUB_CACHE_BIN%;%PATH%"
    echo  [OK] flutterfire: %PUB_CACHE_BIN%
) else (
    echo  [!] Instalare flutterfire CLI...
    call flutter pub global activate flutterfire_cli
    set "PATH=%PUB_CACHE_BIN%;%PATH%"
)

:: Adauga PubCache la PATH permanent
for /f "skip=2 tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
echo !USER_PATH! | findstr /i "Pub\\Cache\\bin" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if defined USER_PATH (
        reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%PUB_CACHE_BIN%;!USER_PATH!" /f >nul
    ) else (
        reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%PUB_CACHE_BIN%" /f >nul
    )
    echo  [OK] PubCache\bin adaugat permanent la PATH
)

cd /d "%~dp0"

echo.
echo  ==========================================
echo  IMPORTANT: Asigura-te ca ai creat proiectul
echo  Firebase inainte sa continui!
echo.
echo  Pasi pregatire Firebase:
echo  1. console.firebase.google.com
echo  2. Add project -> "e-patrimoniu"
echo  3. Authentication -> Sign-in method -> Email/Password -> Enable
echo  4. Firestore Database -> Create database -> Start in test mode
echo  5. Storage -> Get started -> Start in test mode
echo  ==========================================
echo.
echo  Apasa orice tasta cand proiectul Firebase e gata...
pause >nul

echo.
echo  Rulare: flutterfire configure
echo  (Selecteaza proiectul e-patrimoniu si platformele Android + Web)
echo.
call flutterfire configure

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [EROARE] flutterfire configure a esuat.
    echo  Verifica ca ai creat proiectul Firebase si esti autentificat in Google.
    pause >nul
    exit /b 1
)

echo.
echo  ==========================================
echo  [OK] Firebase configurat!
echo  ==========================================
echo.
echo  Acum ruleaza aplicatia:
echo  1. WEB:     flutter run -d chrome
echo  2. Android: flutter run  (cu emulator activ)
echo.
echo  Rulam pe WEB acum? (apasa Y pentru DA, orice alta tasta pentru NU)
choice /c YN /n /m "Alege (Y/N): "
if %ERRORLEVEL% EQU 1 (
    echo.
    echo  Pornire aplicatie in Chrome...
    call flutter run -d chrome
)

pause >nul
