@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo === Curatare cache build ===
flutter clean
echo === Instalare dependente ===
flutter pub get
echo === Pornire flutter run -d chrome ===
flutter run -d chrome
pause
