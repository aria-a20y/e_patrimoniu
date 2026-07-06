@echo off
echo ============================================
echo  Git commit + push cu token GitHub
echo ============================================
echo.
set /p TOKEN="Token (ghp_...): "

if "%TOKEN%"=="" (
    echo Eroare: nu ai introdus niciun token.
    pause
    exit /b 1
)

cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo.
echo Adaug fisierele modificate...
git add -A

echo.
echo Commit...
git commit -m "UI: role cards on register, removed from login"

echo.
echo Push in curs...
git push https://aria-a20y:%TOKEN%@github.com/aria-a20y/e_patrimoniu.git main

echo.
pause
