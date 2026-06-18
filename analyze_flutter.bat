@echo off
set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"
echo === flutter analyze === > flutter_analyze.log 2>&1
flutter analyze --no-pub >> flutter_analyze.log 2>&1
echo EXIT=%ERRORLEVEL% >> flutter_analyze.log 2>&1
echo === DONE === >> flutter_analyze.log 2>&1
