@echo off
set "PATH=%USERPROFILE%\AppData\Roaming\npm;%USERPROFILE%\AppData\Local\Pub\Cache\bin;%USERPROFILE%\flutter\bin;%PATH%"
echo === PASUL 1: Firebase Login ===
echo n | firebase login
echo === PASUL 2: FlutterFire Configure ===
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
flutterfire configure --project=e-patrimoniu --platforms=android,web --yes
echo === GATA! ===
pause
