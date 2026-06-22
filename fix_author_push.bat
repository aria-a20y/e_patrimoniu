@echo off
cd /d "C:\Users\Daria\Desktop\e_Patrimoniu (app)\e_patrimoniu"

echo === Setez autorul git la contul GitHub al proiectului ===
git config user.name "aria-a20y"
git config user.email "dariageo27@gmail.com"

echo.
echo === Amend ultimul commit cu autorul corect ===
git commit --amend --reset-author --no-edit

echo.
echo === Push fortat (rewrite history) ===
git push origin main --force-with-lease

echo.
echo === DONE - Vercel va face deploy acum ===
pause
