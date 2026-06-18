@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo Pornire flutter run -d web-server pe port 3000...
flutter run -d web-server --web-port=3000
pause
