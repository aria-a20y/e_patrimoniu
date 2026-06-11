@echo off
setlocal EnableDelayedExpansion
title e-Patrimoniu - FlutterFire Configure
color 0B

set "FLUTTER_BIN=%USERPROFILE%\flutter\bin"
set "PUB_CACHE_BIN=%USERPROFILE%\AppData\Local\Pub\Cache\bin"
set "PATH=%FLUTTER_BIN%;%PUB_CACHE_BIN%;%PATH%"

cd /d "%~dp0"

echo.
echo  ==========================================
echo    Rulare: flutterfire configure
echo    Proiect: e-patrimoniu
echo    Platforme: android, web
echo  ==========================================
echo.

call flutterfire configure --project=e-patrimoniu --platforms=android,web

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [EROARE] flutterfire configure a esuat.
    echo  Cod eroare: %ERRORLEVEL%
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
