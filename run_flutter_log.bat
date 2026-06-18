@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo === Pornire flutter run web-server pe port 3000 === > flutter_run.log 2>&1
flutter run -d web-server --web-port=3000 >> flutter_run.log 2>&1
echo DONE >> flutter_run.log 2>&1
