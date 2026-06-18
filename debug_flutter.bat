@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo === flutter pub get === > flutter_debug.log 2>&1
flutter pub get >> flutter_debug.log 2>&1
echo === flutter run web-server === >> flutter_debug.log 2>&1
start /b flutter run -d web-server --web-port=3000 >> flutter_debug.log 2>&1
timeout /t 20 /nobreak >> nul
echo === DONE waiting === >> flutter_debug.log 2>&1
taskkill /f /im dart.exe >> flutter_debug.log 2>&1
echo === Log complet === >> flutter_debug.log 2>&1
