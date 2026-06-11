@echo off
setlocal EnableDelayedExpansion
title e-Patrimoniu - Flutter Setup
color 0A

echo.
echo  ==========================================
echo    e-Patrimoniu - Flutter Setup Automat
echo  ==========================================
echo.

:: -----------------------------------------------
:: PASUL 1: Verifica Flutter
:: -----------------------------------------------
echo [1/5] Verificare Flutter SDK...
echo.

set "FLUTTER_CMD="

where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  [OK] Flutter gasit in PATH
    set "FLUTTER_CMD=flutter"
    goto :flutter_ready
)

if exist "C:\flutter\bin\flutter.bat" (
    echo  [OK] Flutter gasit la C:\flutter
    set "PATH=C:\flutter\bin;%PATH%"
    set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
    goto :flutter_ready
)

if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    echo  [OK] Flutter gasit la %USERPROFILE%\flutter
    set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
    set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
    goto :flutter_ready
)

if exist "C:\src\flutter\bin\flutter.bat" (
    echo  [OK] Flutter gasit la C:\src\flutter
    set "PATH=C:\src\flutter\bin;%PATH%"
    set "FLUTTER_CMD=C:\src\flutter\bin\flutter.bat"
    goto :flutter_ready
)

:: Flutter nu e instalat - cauta zip local in Downloads
echo  [!] Flutter SDK nu este instalat. Caut zip local...

set "FLUTTER_ZIP="
set "FLUTTER_INSTALL_DIR=%USERPROFILE%\flutter"

:: Cauta orice flutter zip in Downloads
for %%F in ("%USERPROFILE%\Downloads\flutter_windows_*.zip") do (
    set "FLUTTER_ZIP=%%F"
)

if defined FLUTTER_ZIP (
    echo  [OK] Gasit Flutter zip local: !FLUTTER_ZIP!
    echo  Extragere la %USERPROFILE%... (poate dura 1-2 minute)
    powershell -NoProfile -Command "Expand-Archive -Path '!FLUTTER_ZIP!' -DestinationPath '%USERPROFILE%' -Force"
) else (
    echo  Nu am gasit zip local. Descarcare Flutter 3.41.6 cu curl (~700MB)...
    echo  (Poate dura 5-15 minute)
    echo.
    set "FLUTTER_ZIP=%USERPROFILE%\flutter_sdk.zip"
    curl -L --retry 5 --retry-delay 3 --progress-bar ^
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.6-stable.zip" ^
      -o "!FLUTTER_ZIP!"
    if not exist "!FLUTTER_ZIP!" (
        echo  [EROARE] Descarcare esuata.
        exit /b 1
    )
    powershell -NoProfile -Command "Expand-Archive -Path '!FLUTTER_ZIP!' -DestinationPath '%USERPROFILE%' -Force"
    del "!FLUTTER_ZIP!" 2>nul
)

if not exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    echo  [EROARE] Extractia a esuat. Verifica ca zip-ul nu e corupt.
    exit /b 1
)

set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
echo  [OK] Flutter instalat la %USERPROFILE%\flutter

:: Adauga permanent la PATH utilizator
for /f "skip=2 tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
if not defined USER_PATH (
    reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%USERPROFILE%\flutter\bin" /f >nul
) else (
    echo !USER_PATH! | findstr /i "flutter" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%USERPROFILE%\flutter\bin;!USER_PATH!" /f >nul
    )
)
echo  [OK] Flutter adaugat permanent la PATH

:flutter_ready
echo.
echo  Flutter version:
call "%FLUTTER_CMD%" --version
echo.

:: -----------------------------------------------
:: PASUL 2: flutter doctor
:: -----------------------------------------------
echo  ==========================================
echo [2/5] Flutter doctor...
echo  ==========================================
echo.
call "%FLUTTER_CMD%" doctor
echo.

:: -----------------------------------------------
:: PASUL 3: Genereaza platforma web + android
:: -----------------------------------------------
echo  ==========================================
echo [3/5] Generare fisiere platforma (web + android)...
echo  ==========================================
echo.
cd /d "%~dp0"
call "%FLUTTER_CMD%" create --org ro.epatrimoniu --project-name e_patrimoniu --platforms=web,android .
echo.

:: -----------------------------------------------
:: PASUL 4: flutter pub get
:: -----------------------------------------------
echo  ==========================================
echo [4/5] Instalare dependente...
echo  ==========================================
echo.
call "%FLUTTER_CMD%" pub get
echo.

:: -----------------------------------------------
:: PASUL 5: FlutterFire CLI
:: -----------------------------------------------
echo  ==========================================
echo [5/5] Instalare FlutterFire CLI...
echo  ==========================================
echo.
call "%FLUTTER_CMD%" pub global activate flutterfire_cli
echo.

:: -----------------------------------------------
:: GATA
:: -----------------------------------------------
echo.
echo  ==========================================
echo  SETUP FLUTTER COMPLET!
echo  ==========================================
echo.
echo  PASUL URMATOR - CONFIGURARE FIREBASE:
echo.
echo  1. Deschide: https://console.firebase.google.com
echo  2. Clic "Add project"  ->  denumeste-l: e-patrimoniu
echo  3. Activeaza: Authentication, Firestore, Storage
echo  4. In acest folder, ruleaza:
echo        flutterfire configure
echo  5. Selecteaza proiectul "e-patrimoniu"
echo  6. Alege platformele: Android + Web
echo.
echo  Dupa configurare Firebase:
echo        flutter run -d chrome       (web)
echo        flutter run                 (Android cu emulator)
echo.
start "" "https://console.firebase.google.com"
echo  [OK] Firebase Console deschis in browser.
echo.
echo  Apasa orice tasta pentru a inchide...
pause >nul
