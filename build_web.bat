@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo ==> Flutter build web starting...
flutter build web --release --dart-define=BACKEND_URL=https://e-patrimoniu-api.onrender.com
echo.
echo EXIT CODE: %ERRORLEVEL%
echo ==> Done. Press any key to close.
pause
